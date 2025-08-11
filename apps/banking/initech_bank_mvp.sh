#!/usr/local/bin/bash
# Optional portable launcher: uncomment if you want auto-fallback on Linux.
# [ -n "$BASH_VERSION" ] || exec /usr/bin/env bash "$0" "$@"
##############################################################################
# INITECH BANKING SYSTEM (Late 90's MVP + Office Space gag)
# Solaris 7 + dialog 1.0  |  Ubuntu 24 + dialog 1.3
#
# Wire upgrades:
# - Dual control (maker/checker) on release
# - OFAC scan against $STATE_DIR/ofac_list.txt (substring/word match)
# - Wire history log at $DATA_ROOT/wires/wires.log
# - Amend pending wires (edit, re-run checks)
# - Cancel pending wires with reason (archive)
# - Printable Fedwire-style text stub per wire
# Compat work:
# - No process substitution / here-strings
# - XPG4 tool fallbacks; POSIX-safe grep usage
##############################################################################

# -----------------------------
# Config / Environment
# -----------------------------
TITLE="INITECH BANKING SYSTEM"
BACKTITLE="INITECH - Financial Systems (Late 90's TUI)"
DATA_ROOT="/export/banking"
LOG_DIR="$DATA_ROOT/log"
ACH_INBOX="$DATA_ROOT/ach/incoming"       # batch (received)
ACH_OUTBOX="$DATA_ROOT/ach/outgoing"      # batch (to send)
WIRE_QUEUE="$DATA_ROOT/wires/pending"     # manual review/release
WIRE_RELEASED="$DATA_ROOT/wires/released" # archive
WIRE_CANCELED="$DATA_ROOT/wires/canceled" # archive
WIRE_FORMS="$DATA_ROOT/wires/forms"       # printable stubs
DOC_STORE="$DATA_ROOT/docs"               # paper/microfilm placeholder
STATE_DIR="$DATA_ROOT/state"              # misc state
PROJECT_DIR="$DATA_ROOT/special_projects" # Peter's playground
WIRE_HISTORY="$DATA_ROOT/wires/wires.log" # consolidated history
OFAC_LIST="$STATE_DIR/ofac_list.txt"      # simple list (one name/keyword per line)
HIGH_VALUE_THRESHOLD="10000.00"           # demo threshold for extra confirm

## Prefer system tools if present; include Solaris XPG4 fallbacks
if command -v gawk >/dev/null 2>&1; then
  AWK=$(command -v gawk)
elif [ -x /usr/local/bin/gawk ]; then
  AWK=/usr/local/bin/gawk
elif [ -x /usr/xpg4/bin/awk ]; then
  AWK=/usr/xpg4/bin/awk
else
  AWK=/usr/bin/awk
fi

if [ -x /usr/xpg4/bin/grep ]; then
  GREP=/usr/xpg4/bin/grep
else
  GREP=/usr/bin/grep
fi

if command -v dialog >/dev/null 2>&1; then
  DIALOG=$(command -v dialog)
elif [ -x /usr/local/bin/dialog ]; then
  DIALOG=/usr/local/bin/dialog
else
  DIALOG=/usr/bin/dialog
fi

# tail: prefer XPG4 on Solaris for -n support
if [ -x /usr/xpg4/bin/tail ]; then
  TAILBIN=/usr/xpg4/bin/tail
else
  TAILBIN=/usr/bin/tail
fi

# Temporary file for dialog input/output (no mktemp on stock Solaris 7)
TMP="/tmp/initech.$$"
trap 'rm -f "$TMP"*; clear' EXIT HUP INT TERM

# -----------------------------
# Helpers
# -----------------------------
die() { echo "ERROR: $*" >&2; exit 1; }

ensure_env() {
  [ -x "$DIALOG" ] || die "dialog(1) not found. Install dialog in /usr/local/bin."
  for d in "$DATA_ROOT" "$LOG_DIR" "$ACH_INBOX" "$ACH_OUTBOX" "$WIRE_QUEUE" \
           "$DOC_STORE" "$STATE_DIR" "$PROJECT_DIR" "$WIRE_RELEASED" "$WIRE_CANCELED" \
           "$WIRE_FORMS"; do
    [ -d "$d" ] || mkdir -p "$d" || die "Cannot create $d"
  done
  : > "$LOG_DIR/ops.log"       2>/dev/null || true
  : > "$STATE_DIR/accounts.db" 2>/dev/null || true
  : > "$WIRE_HISTORY"          2>/dev/null || true

  # seed OFAC list placeholder if absent
  if [ ! -f "$OFAC_LIST" ]; then
    cat > "$OFAC_LIST" <<EOF
# Simple OFAC name/keyword list (demo)
# One entry per line; case-insensitive substring match
GARCIA
IVANOV
PC LOAD LETTER LLC
EOF
  fi
}

log_op() {
  # log_op "category" "message"
  printf '%s | %s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" >> "$LOG_DIR/ops.log"
}

log_wire() {
  # log_wire "WIRE_ID" "event" "detail"
  printf '%s | %s | %s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" "$3" >> "$WIRE_HISTORY"
}

msg() {
  "$DIALOG" --backtitle "$BACKTITLE" --title "$TITLE" --msgbox "$1" 12 70
}

ask_input() {
  # ask_input "Title" "Prompt" "default"
  local title="$1" prompt="$2" defval="$3"
  "$DIALOG" --backtitle "$BACKTITLE" --title "$title" --inputbox "$prompt" 10 70 "$defval" 2>"$TMP.in"
  return $?
}

confirm() {
  # confirm "Question?"
  "$DIALOG" --backtitle "$BACKTITLE" --title "$TITLE" --yesno "$1" 8 60
}

to_upper() {
  echo "$1" | $AWK '{print toupper($0)}'
}

# -----------------------------
# Easter Eggs / Security Comedy
# -----------------------------
milton_lockdown() {
  log_op "SECURITY" "Milton Incident triggered — forbidden wire amount 911"
  "$DIALOG" --backtitle "$BACKTITLE" --title "SECURITY LOCKDOWN" \
    --msgbox "Uh... yeah... hi. I'm gonna need you to stop doing that.\n\n\
Milton here says if you try that again, he's going to burn the building down.\n\n\
Also, have you seen his red Swingline stapler?" 15 70
  clear
  echo "=== TERMINAL LOCKED DUE TO MILTON INCIDENT ==="
  echo "Please contact Lumbergh for access restoration. M'kay?"
  sleep 5
  exit 99
}

lumbergh_lockout() {
  log_op "SECURITY" "Lumbergh lockout after 3 failed TPS unlock attempts"
  "$DIALOG" --backtitle "$BACKTITLE" --title "ACCESS DENIED" \
    --msgbox "Yeah... if you could go ahead and stop guessing the code, that'd be great.\n\n\
So I'm gonna need you to come in on Saturday. M'kay?" 13 70
  clear
  echo "=== ACCESS DENIED BY LUMBERGH ==="
  echo "Please reflect on your choices this weekend."
  sleep 4
  exit 98
}

# -----------------------------
# Wire helpers (load/save/print/check)
# -----------------------------
generate_wire_id() {
  echo "WIRE.$(date '+%Y%m%d%H%M%S').$$"
}

save_wire_file() {
  # Expected vars: DACC CNAME CABA CACC AMT TYPE MEMO REQDATE MAKER OFAC STATUS TS
  printf "DACC=%s|CNAME=%s|CABA=%s|CACC=%s|AMT=%s|TYPE=%s|MEMO=%s|REQDATE=%s|MAKER=%s|OFAC=%s|STATUS=%s|TS=%s\n" \
    "$DACC" "$CNAME" "$CABA" "$CACC" "$AMT" "$TYPE" "$MEMO" "$REQDATE" "$MAKER" "$OFAC" "$STATUS" "$TS" > "$1"
}

load_wire_file() {
  # POSIX-safe load without arrays or process substitution
  # sets vars in current shell (DACC, CNAME, ...)
  # shellcheck disable=SC2163
  local content kv k v OLDIFS
  content=$(cat "$1")
  OLDIFS="$IFS"; IFS='|'
  for kv in $content; do
    k="${kv%%=*}"
    v="${kv#*=}"
    eval "$k=\"\$v\""
  done
  IFS="$OLDIFS"
}

ofac_scan_name() {
  # Returns 0 if PASS, 1 if REVIEW
  # Case-insensitive substring match against non-empty, non-comment lines
  local name_upper pat pat_upper
  name_upper=$(to_upper "$1")
  if [ ! -s "$OFAC_LIST" ]; then
    return 0
  fi
  while IFS= read -r pat; do
    # skip blanks/comments
    [ -z "$pat" ] && continue
    case "$pat" in \#*) continue;; esac
    pat_upper=$(to_upper "$pat")
    echo "$name_upper" | $GREP -F -i "$pat_upper" >/dev/null 2>&1 && return 1
  done < "$OFAC_LIST"
  return 0
}

compare_money_ge() {
  # usage: compare_money_ge A B ; return 0 if A >= B else 1
  echo | $AWK -v a="$1" -v b="$2" 'BEGIN{ if (a+0 >= b+0) exit 0; else exit 1 }'
}

print_fedwire_form() {
  local id="$1" path="$WIRE_FORMS/${id}.txt" hv="NO"
  if compare_money_ge "$AMT" "$HIGH_VALUE_THRESHOLD"; then hv="YES"; fi
  cat > "$path" <<EOF
INITECH WIRE TRANSFER REQUEST (Fedwire Stub)
------------------------------------------------------------
Wire ID:           $id
Requested Date:    ${REQDATE:-$(date '+%Y-%m-%d')}
Entered Timestamp: $TS
Maker (Entered by): $MAKER

DEBIT (Sender)
  Account: $DACC

CREDIT (Beneficiary)
  Name:    $CNAME
  ABA:     $CABA
  Acct:    $CACC

AMOUNT (USD):      $AMT
TYPE:              ${TYPE:-DOMESTIC}
MEMO/REF:          ${MEMO:-N/A}

Compliance:
  OFAC Status:     $OFAC
  High-Value:      $hv

Status:            $STATUS

Operator Notes:
  (Affix manual approvals / signatures here)
------------------------------------------------------------
EOF
  echo "$path"
}

list_pending_ids() {
  (cd "$WIRE_QUEUE" 2>/dev/null && ls -1 WIRE.* 2>/dev/null) || true
}

# -----------------------------
# Menus (functional)
# -----------------------------

# 1) Customer & Account Mgmt
customer_menu() {
  while :; do
    CHOICE=$("$DIALOG" --clear --backtitle "$BACKTITLE" --title "Customer & Account Management" \
      --menu "Select a function" 18 70 10 \
      1 "Open Account (branch/manual KYC)" \
      2 "Close/Freeze Account" \
      3 "Manage Signers / Authorized Users" \
      4 "Lookup Customer / Accounts" \
      5 "Return to Main Menu" \
      3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    case "$CHOICE" in
      1)
        ask_input "Open Account" "Customer Name:" "" || continue
        NAME=$(cat "$TMP.in")
        ask_input "Open Account" "SSN / EIN:" "" || continue
        TAXID=$(cat "$TMP.in")
        ask_input "Open Account" "Product (e.g., CHK, SAV, ANALYSIS):" "CHK" || continue
        PROD=$(cat "$TMP.in")
        echo "$NAME|$TAXID|$PROD|$(date '+%Y%m%d')" >> "$STATE_DIR/accounts.db"
        log_op "ACCOUNT" "Open requested: $NAME / $TAXID / $PROD"
        msg "Open request recorded (paper KYC, signature card, and core entry to be completed)."
        ;;
      2)
        ask_input "Close/Freeze" "Account Number:" "" || continue
        ACCT=$(cat "$TMP.in")
        confirm "Freeze account $ACCT?\n\nSelect Yes to Freeze, No to Close (stub)."
        if [ $? -eq 0 ]; then
          log_op "ACCOUNT" "Freeze requested: $ACCT"
          msg "Freeze request recorded (requires core action)."
        else
          log_op "ACCOUNT" "Close requested: $ACCT"
          msg "Close request recorded (requires core action)."
        fi
        ;;
      3)
        ask_input "Signers" "Account Number:" "" || continue
        ACCT=$(cat "$TMP.in")
        ask_input "Signers" "Add or Remove signer? (ADD/REMOVE)" "ADD" || continue
        ACT=$(cat "$TMP.in")
        ask_input "Signers" "Signer Name:" "" || continue
        SNAME=$(cat "$TMP.in")
        log_op "SIGNERS" "$ACT signer '$SNAME' on $ACCT"
        msg "Signer change recorded (manual approval path required)."
        ;;
      4)
        ask_input "Lookup" "Search by Name/TaxID/Acct:" "" || continue
        Q=$(cat "$TMP.in")
        RES=$($AWK -F'|' -v q="$Q" '{ if ($0 ~ q) print }' "$STATE_DIR/accounts.db" 2>/dev/null)
        [ -z "$RES" ] && RES="No matches."
        "$DIALOG" --backtitle "$BACKTITLE" --title "Lookup Results" --msgbox "$RES" 15 70
        ;;
      5) return;;
    esac
  done
}

# 2) Payments (ACH + Wires) — enhanced wires
payments_menu() {
  while :; do
    CHOICE=$("$DIALOG" --clear --backtitle "$BACKTITLE" --title "Payments (Batch ACH & Wires)" \
      --menu "Select a function" 20 74 10 \
      1 "ACH: Receive (view inbox)" \
      2 "ACH: Originate (queue NACHA file)" \
      3 "ACH: Returns (log code & note)" \
      4 "Wires: Enter Wire (pending queue)" \
      5 "Wires: Review/Release (dual control)" \
      6 "Wires: Amend Pending" \
      7 "Wires: Cancel Pending" \
      8 "Wires: Print Fedwire Form" \
      9 "Wires: History Log (view tail)" \
      10 "Return to Main Menu" \
      3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    case "$CHOICE" in
      1)
        LIST=$(ls -1 "$ACH_INBOX" 2>/dev/null)
        [ -z "$LIST" ] && LIST="(empty)"
        "$DIALOG" --backtitle "$BACKTITLE" --title "ACH Inbox" --msgbox "$LIST" 18 70
        ;;
      2)
        ask_input "ACH Origination" "Path to NACHA file to queue for send:" "" || continue
        SRC=$(cat "$TMP.in")
        if [ -f "$SRC" ]; then
          BASENAME=$(basename "$SRC")
          cp "$SRC" "$ACH_OUTBOX/$BASENAME" && \
            log_op "ACH" "Queued for send: $BASENAME" && \
            msg "Queued: $BASENAME"
        else
          msg "File not found."
        fi
        ;;
      3)
        ask_input "ACH Return" "Enter Return Code (e.g., R01-R85):" "R01" || continue
        RC=$(cat "$TMP.in")
        ask_input "ACH Return" "Related Account/Trace (free text):" "" || continue
        NOTE=$(cat "$TMP.in")
        log_op "ACH_RETURN" "$RC | $NOTE"
        msg "Return logged."
        ;;
      4)  # Wire Entry
        ask_input "Wire Entry" "Debit Account:" "" || continue; DACC=$(cat "$TMP.in")
        ask_input "Wire Entry" "Credit Name:" "" || continue; CNAME=$(cat "$TMP.in")
        ask_input "Wire Entry" "Credit ABA (or SWIFT for intl):" "" || continue; CABA=$(cat "$TMP.in")
        ask_input "Wire Entry" "Credit Account:" "" || continue; CACC=$(cat "$TMP.in")
        ask_input "Wire Entry" "Amount (USD):" "" || continue; AMT=$(cat "$TMP.in")
        [ "$AMT" = "911" ] && milton_lockdown
        ask_input "Wire Entry" "Type (DOMESTIC/INTERNATIONAL):" "DOMESTIC" || continue; TYPE=$(to_upper "$(cat "$TMP.in")")
        ask_input "Wire Entry" "Memo / Reference:" "" || continue; MEMO=$(cat "$TMP.in")
        ask_input "Wire Entry" "Requested Date (YYYY-MM-DD) or blank for today:" "$(date '+%Y-%m-%d')" || continue; REQDATE=$(cat "$TMP.in")
        MAKER="${USER:-operator}"
        TS="$(date '+%Y-%m-%d %H:%M:%S')"
        OFAC="PASS"; if ! ofac_scan_name "$CNAME"; then OFAC="REVIEW"; fi
        STATUS="PENDING"
        ID=$(generate_wire_id)
        FILE="$WIRE_QUEUE/$ID"
        save_wire_file "$FILE"
        log_op "WIRE" "Entered $ID for review (OFAC=$OFAC, MAKER=$MAKER)"
        log_wire "$ID" "ENTERED" "maker=$MAKER; ofac=$OFAC; amt=$AMT; type=$TYPE"
        if compare_money_ge "$AMT" "$HIGH_VALUE_THRESHOLD"; then
          msg "Wire $ID entered.\nHigh-value alert: amount >= \$$HIGH_VALUE_THRESHOLD\nOFAC: $OFAC\nPending dual control."
        else
          msg "Wire $ID entered.\nOFAC: $OFAC\nPending dual control."
        fi
        ;;
      5)  # Review / Release (dual control)
        PENDING=$(list_pending_ids)
        if [ -z "$PENDING" ]; then msg "No pending wires."; continue; fi
        ask_input "Release Wire" "Enter pending wire ID to release (or CANCEL):\n\n$(echo "$PENDING")" "" || continue
        WID=$(cat "$TMP.in")
        [ "$WID" = "CANCEL" ] && continue
        FILE="$WIRE_QUEUE/$WID"
        if [ ! -f "$FILE" ]; then msg "ID not found."; continue; fi
        load_wire_file "$FILE"
        ask_input "Dual Control" "Enter Approver ID (must differ from Maker '$MAKER'):" "" || continue
        APPROVER=$(cat "$TMP.in")
        if [ "$APPROVER" = "$MAKER" ]; then
          msg "Approver cannot be the same as Maker."
          continue
        fi
        SUMMARY="Release $WID?\n\nDebit: $DACC\nCredit: $CNAME ($CABA/$CACC)\nAmount: \$$AMT\nType: $TYPE\nMemo: ${MEMO:-N/A}\nOFAC: $OFAC\nMaker: $MAKER\nApprover: $APPROVER"
        if [ "$OFAC" = "REVIEW" ]; then
          confirm "$SUMMARY\n\nOFAC flagged for REVIEW. Override and proceed?"
          [ $? -ne 0 ] && { msg "Release aborted."; continue; }
        else
          confirm "$SUMMARY"
          [ $? -ne 0 ] && { msg "Not released."; continue; }
        fi
        if compare_money_ge "$AMT" "$HIGH_VALUE_THRESHOLD"; then
          confirm "High-value wire (>= \$$HIGH_VALUE_THRESHOLD). Confirm release again?"
          [ $? -ne 0 ] && { msg "Not released."; continue; }
        fi
        STATUS="RELEASED"
        save_wire_file "$FILE"
        mv "$FILE" "$WIRE_RELEASED/${WID}.released"
        log_op "WIRE" "Released $WID (maker=$MAKER approver=$APPROVER ofac=$OFAC)"
        log_wire "$WID" "RELEASED" "approver=$APPROVER"
        FORM_PATH=$(print_fedwire_form "$WID")
        msg "Released $WID.\nFedwire stub saved:\n$FORM_PATH"
        ;;
      6)  # Amend pending
        PENDING=$(list_pending_ids)
        if [ -z "$PENDING" ]; then msg "No pending wires to amend."; continue; fi
        ask_input "Amend Wire" "Enter pending wire ID to amend (or CANCEL):\n\n$(echo "$PENDING")" "" || continue
        WID=$(cat "$TMP.in")
        [ "$WID" = "CANCEL" ] && continue
        FILE="$WIRE_QUEUE/$WID"
        if [ ! -f "$FILE" ]; then msg "ID not found."; continue; fi
        load_wire_file "$FILE"
        ask_input "Amend $WID" "Beneficiary Name:" "$CNAME" || continue; CNAME=$(cat "$TMP.in")
        ask_input "Amend $WID" "Credit ABA/SWIFT:" "$CABA" || continue; CABA=$(cat "$TMP.in")
        ask_input "Amend $WID" "Credit Account:" "$CACC" || continue; CACC=$(cat "$TMP.in")
        ask_input "Amend $WID" "Amount (USD):" "$AMT" || continue; AMT=$(cat "$TMP.in")
        [ "$AMT" = "911" ] && milton_lockdown
        ask_input "Amend $WID" "Type (DOMESTIC/INTERNATIONAL):" "$TYPE" || continue; TYPE=$(to_upper "$(cat "$TMP.in")")
        ask_input "Amend $WID" "Memo / Reference:" "$MEMO" || continue; MEMO=$(cat "$TMP.in")
        ask_input "Amend $WID" "Requested Date (YYYY-MM-DD):" "$REQDATE" || continue; REQDATE=$(cat "$TMP.in")
        TS="$(date '+%Y-%m-%d %H:%M:%S')"
        OFAC="PASS"; if ! ofac_scan_name "$CNAME"; then OFAC="REVIEW"; fi
        STATUS="PENDING"
        save_wire_file "$FILE"
        log_op "WIRE" "Amended $WID (OFAC=$OFAC)"
        log_wire "$WID" "AMENDED" "ofac=$OFAC; amt=$AMT; type=$TYPE"
        msg "$WID amended.\nOFAC: $OFAC"
        ;;
      7)  # Cancel pending
        PENDING=$(list_pending_ids)
        if [ -z "$PENDING" ]; then msg "No pending wires to cancel."; continue; fi
        ask_input "Cancel Wire" "Enter pending wire ID to cancel (or CANCEL):\n\n$(echo "$PENDING")" "" || continue
        WID=$(cat "$TMP.in")
        [ "$WID" = "CANCEL" ] && continue
        FILE="$WIRE_QUEUE/$WID"
        if [ ! -f "$FILE" ]; then msg "ID not found."; continue; fi
        ask_input "Cancel Reason" "Enter reason for cancellation:" "" || continue
        REASON=$(cat "$TMP.in")
        load_wire_file "$FILE"
        STATUS="CANCELED"
        save_wire_file "$FILE"
        mv "$FILE" "$WIRE_CANCELED/${WID}.canceled"
        log_op "WIRE" "Canceled $WID (reason: $REASON)"
        log_wire "$WID" "CANCELED" "reason=$REASON"
        msg "Canceled $WID.\nReason: $REASON"
        ;;
      8)  # Print Fedwire form
        ask_input "Print Form" "Enter wire ID to print stub (pending or released ID accepted):" "" || continue
        WID=$(cat "$TMP.in")
        FILE="$WIRE_QUEUE/$WID"
        [ -f "$FILE" ] || FILE="$WIRE_RELEASED/${WID}.released"
        if [ ! -f "$FILE" ]; then msg "ID not found in pending or released archive."; continue; fi
        load_wire_file "$FILE"
        PATH_OUT=$(print_fedwire_form "$WID")
        msg "Form written to:\n$PATH_OUT"
        ;;
      9)  # View wire history
        _H=$($TAILBIN -n 40 "$WIRE_HISTORY" 2>/dev/null)
        [ -z "$_H" ] && _H="No wire history yet."
        "$DIALOG" --backtitle "$BACKTITLE" --title "Wire History (last 40)" --msgbox "$_H" 20 80
        ;;
      10) return;;
    esac
  done
}

# 3) Account Info & Statements
statements_menu() {
  while :; do
    CHOICE=$("$DIALOG" --clear --backtitle "$BACKTITLE" --title "Account Info & Statements" \
      --menu "Select a function" 18 70 10 \
      1 "End-of-Day Balances (stub view)" \
      2 "Monthly Statements (paper queue)" \
      3 "Commercial Exports (BAI2/fixed-width stub)" \
      4 "Return to Main Menu" \
      3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    case "$CHOICE" in
      1)
        RES=$($TAILBIN -n 10 "$STATE_DIR/accounts.db" 2>/dev/null)
        [ -z "$RES" ] && RES="No data yet."
        "$DIALOG" --backtitle "$BACKTITLE" --title "EoD Balances (Demo)" --msgbox "$RES" 18 70
        ;;
      2)
        ask_input "Monthly Statements" "Enter Account Number (or ALL):" "ALL" || continue
        AC=$(cat "$TMP.in")
        log_op "STATEMENTS" "Queued monthly statements for: $AC"
        msg "Statement job queued (paper print workflow stub)."
        ;;
      3)
        ask_input "Commercial Export" "Customer/Account selector (free text):" "" || continue
        SEL=$(cat "$TMP.in")
        OUT="$STATE_DIR/export_$(date '+%Y%m%d_%H%M%S').bai2"
        echo "BAI2/FixedWidth placeholder for [$SEL] at $(date)" > "$OUT"
        log_op "EXPORT" "Generated $OUT for $SEL"
        msg "Export created: $OUT"
        ;;
      4) return;;
    esac
  done
}

# 4) Fraud, Risk & Compliance
compliance_menu() {
  while :; do
    CHOICE=$("$DIALOG" --clear --backtitle "$BACKTITLE" --title "Fraud, Risk & Compliance" \
      --menu "Select a function" 18 70 10 \
      1 "OFAC Check (manual log)" \
      2 "CTR Paper Filing (log stub)" \
      3 "Audit Log (tail view)" \
      4 "Return to Main Menu" \
      3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    case "$CHOICE" in
      1)
        ask_input "OFAC" "Name or Reference to check (manual process in 90s):" "" || continue
        REF=$(cat "$TMP.in")
        log_op "OFAC" "Manual check recorded for: $REF"
        msg "OFAC check noted (manual process—retain paper evidence).\n\nShared list at: $OFAC_LIST"
        ;;
      2)
        ask_input "CTR Filing" "Transaction Reference / Notes:" "" || continue
        REF=$(cat "$TMP.in")
        log_op "CTR" "Paper CTR filed for: $REF"
        msg "CTR filing logged (paper form mailed to FinCEN)."
        ;;
      3)
        _LOG=$($TAILBIN -n 30 "$LOG_DIR/ops.log" 2>/dev/null)
        [ -z "$_LOG" ] && _LOG="No log entries."
        "$DIALOG" --backtitle "$BACKTITLE" --title "Audit Log (last 30)" --msgbox "$_LOG" 20 80
        ;;
      4) return;;
    esac
  done
}

# 5) Back Office Operations
ops_menu() {
  while :; do
    CHOICE=$("$DIALOG" --clear --backtitle "$BACKTITLE" --title "Back Office Operations" \
      --menu "Select a function" 18 70 10 \
      1 "ACH Batch: Post Incoming (stub)" \
      2 "ACH Batch: Send Outgoing (stub)" \
      3 "End-of-Day Posting & Reconciliation (stub)" \
      4 "Document Storage (paper/microfilm placeholder)" \
      5 "Return to Main Menu" \
      3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    case "$CHOICE" in
      1)
        CNT=$(ls -1 "$ACH_INBOX" 2>/dev/null | wc -l | $AWK '{print $1}')
        log_op "ACH_POST" "Posted $CNT incoming files (stub)."
        msg "Simulated posting of $CNT incoming ACH files."
        ;;
      2)
        CNT=$(ls -1 "$ACH_OUTBOX" 2>/dev/null | wc -l | $AWK '{print $1}')
        log_op "ACH_SEND" "Transmitted $CNT outgoing files (stub)."
        msg "Simulated transmission of $CNT outgoing files."
        ;;
      3)
        log_op "EOD" "EoD posting & reconciliation completed (stub)."
        msg "EoD posting & reconciliation simulated."
        ;;
      4)
        msg "Physical documents to be filed; optical/microfilm index simulated at: $DOC_STORE"
        ;;
      5) return;;
    esac
  done
}

# 6) Special Projects (Peter's secret menu)
special_projects_menu() {
  while :; do
    CHOICE=$("$DIALOG" --clear --backtitle "$BACKTITLE" --title "Special Projects" \
      --menu "Totally normal internal tools" 18 70 8 \
      1 "Configure Rounding Error Parameters" \
      2 "Run Daily Skim Job" \
      3 "Deposit Skim Funds to Slush Account" \
      4 "Generate Fake Audit Report" \
      5 "Return to Main Menu" \
      3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    case "$CHOICE" in
      1)
        ask_input "Rounding Error" "Enter max rounding error (in cents):" "0.5" || continue
        VAL=$(cat "$TMP.in")
        echo "$VAL" > "$PROJECT_DIR/rounding.cfg"
        log_op "PROJECT" "Set rounding error to $VAL cents"
        msg "Rounding error set to $VAL cents.\nAs Peter says, 'It's just fractions of a cent...'"
        ;;
      2)
        log_op "PROJECT" "Daily skim executed"
        msg "Daily skim complete.\nPennies redirected to special ledger.\nLumbergh will never notice."
        ;;
      3)
        log_op "PROJECT" "Slush account credited"
        msg "Funds moved to 'PC LOAD LETTER LLC' account.\nLooks legit."
        ;;
      4)
        log_op "PROJECT" "Fake audit generated"
        msg "Audit report created.\nOmitted 'Special Projects' line item as requested."
        ;;
      5) return;;
    esac
  done
}

# -----------------------------
# Main Menu (dynamic)
# -----------------------------
main_menu() {
  while :; do
    if [ "$SPECIAL_UNLOCK" = "yes" ]; then
      CHOICE=$("$DIALOG" --clear --backtitle "$BACKTITLE" --title "$TITLE" \
        --menu "Main Menu" 18 70 10 \
        1 "Customer & Account Management" \
        2 "Payments (ACH + Wires)" \
        3 "Account Info & Statements" \
        4 "Fraud, Risk & Compliance" \
        5 "Back Office Operations" \
        6 "Special Projects" \
        7 "Exit" \
        3>&1 1>&2 2>&3) || exit 0

      case "$CHOICE" in
        1) customer_menu;;
        2) payments_menu;;
        3) statements_menu;;
        4) compliance_menu;;
        5) ops_menu;;
        6) special_projects_menu;;
        7) clear; exit 0;;
      esac
    else
      CHOICE=$("$DIALOG" --clear --backtitle "$BACKTITLE" --title "$TITLE" \
        --menu "Main Menu" 18 70 10 \
        1 "Customer & Account Management" \
        2 "Payments (ACH + Wires)" \
        3 "Account Info & Statements" \
        4 "Fraud, Risk & Compliance" \
        5 "Back Office Operations" \
        6 "Exit" \
        3>&1 1>&2 2>&3) || exit 0

      case "$CHOICE" in
        1) customer_menu;;
        2) payments_menu;;
        3) statements_menu;;
        4) compliance_menu;;
        5) ops_menu;;
        6) clear; exit 0;;
      esac
    fi
  done
}

# -----------------------------
# Bootstrap + Secret Unlock
# -----------------------------
ensure_env

SPECIAL_UNLOCK="no"

ask_input "Access Code" "Enter access code (or press Enter to continue):" "" || exit 0
CODE=$(cat "$TMP.in")

case "$CODE" in
  "TPS")
    SPECIAL_UNLOCK="yes"
    log_op "SECURITY" "Special Projects menu unlocked via TPS"
    msg "Access granted.
Welcome to Special Projects, Peter."
    ;;
  "911")
    milton_lockdown
    ;;
  *)
    [ -n "$CODE" ] && log_op "SECURITY" "Non-special access code entered; proceeding normally"
    ;;
esac

main_menu
