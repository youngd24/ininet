#!/usr/local/bin/bash
##############################################################################
# INITECH BANKING SYSTEM (Late 90's MVP + Office Space gag)
# Solaris 7 + dialog 1.0
#
# Features:
# - Full MVP menus: Customer, Payments (ACH/Wires), Statements, Compliance, Ops
# - Secret unlock code "TPS" reveals "Special Projects" (rounding error fun)
# - 3 failed unlock attempts => Lumbergh lockout
# - Wire amount == 911 => Milton lockdown
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
DOC_STORE="$DATA_ROOT/docs"               # paper/microfilm placeholder
STATE_DIR="$DATA_ROOT/state"              # misc state
PROJECT_DIR="$DATA_ROOT/special_projects" # Peter's playground

# Prefer GNU awk if present; Solaris-safe fallback
AWK=/usr/local/bin/gawk; [ -x "$AWK" ] || AWK=/usr/xpg4/bin/awk
GREP=/usr/xpg4/bin/grep; [ -x "$GREP" ] || GREP=/usr/bin/grep

# dialog path (Solaris packages often install in /usr/local/bin)
DIALOG="/usr/local/bin/dialog"
[ -x "$DIALOG" ] || DIALOG="/usr/bin/dialog"

# Temporary file for dialog input/output (no mktemp on stock Solaris 7)
TMP="/tmp/initech.$$"
trap 'rm -f "$TMP"*; clear' EXIT HUP INT TERM

# -----------------------------
# Helpers
# -----------------------------
die() { echo "ERROR: $*" >&2; exit 1; }

ensure_env() {
  [ -x "$DIALOG" ] || die "dialog(1) not found. Install dialog 1.0 in /usr/local/bin."
  for d in "$DATA_ROOT" "$LOG_DIR" "$ACH_INBOX" "$ACH_OUTBOX" "$WIRE_QUEUE" "$DOC_STORE" "$STATE_DIR" "$PROJECT_DIR"; do
    [ -d "$d" ] || mkdir -p "$d" || die "Cannot create $d"
  done
  # seed files if missing
  [ -f "$STATE_DIR/accounts.db" ] || : > "$STATE_DIR/accounts.db"
  [ -f "$LOG_DIR/ops.log" ] || : > "$LOG_DIR/ops.log"
}

log_op() {
  # log_op "category" "message"
  printf '%s | %s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" >> "$LOG_DIR/ops.log"
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

# 2) Payments (ACH + Wires)
payments_menu() {
  while :; do
    CHOICE=$("$DIALOG" --clear --backtitle "$BACKTITLE" --title "Payments (Batch ACH & Wires)" \
      --menu "Select a function" 18 70 10 \
      1 "ACH: Receive (view inbox)" \
      2 "ACH: Originate (queue NACHA file)" \
      3 "ACH: Returns (log code & note)" \
      4 "Wires: Enter Wire (pending queue)" \
      5 "Wires: Review/Release" \
      6 "Return to Main Menu" \
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
      4)
        ask_input "Wire Entry" "Debit Account:" "" || continue; DACC=$(cat "$TMP.in")
        ask_input "Wire Entry" "Credit Name:" "" || continue; CNAME=$(cat "$TMP.in")
        ask_input "Wire Entry" "Credit ABA:" "" || continue; CABA=$(cat "$TMP.in")
        ask_input "Wire Entry" "Credit Account:" "" || continue; CACC=$(cat "$TMP.in")
        ask_input "Wire Entry" "Amount (USD):" "" || continue; AMT=$(cat "$TMP.in")
        [ "$AMT" = "911" ] && milton_lockdown
        ID="WIRE.$(date '+%Y%m%d%H%M%S').$$"
        printf "DACC=%s|CNAME=%s|CABA=%s|CACC=%s|AMT=%s|TS=%s\n" \
          "$DACC" "$CNAME" "$CABA" "$CACC" "$AMT" "$(date '+%F %T')" > "$WIRE_QUEUE/$ID"
        log_op "WIRE" "Entered $ID for review"
        msg "Wire entered as $ID (pending manual verification/dual control)."
        ;;
      5)
        LIST=$(ls -1 "$WIRE_QUEUE" 2>/dev/null)
        if [ -z "$LIST" ]; then
          msg "No pending wires."
        else
          ask_input "Release Wire" "Enter pending wire ID to release (or type CANCEL):" "" || continue
          WID=$(cat "$TMP.in")
          [ "$WID" = "CANCEL" ] && continue
          if [ -f "$WIRE_QUEUE/$WID" ]; then
            confirm "Release $WID now?\nThis simulates Fedwire submission."
            if [ $? -eq 0 ]; then
              log_op "WIRE" "Released $WID"
              mv "$WIRE_QUEUE/$WID" "$STATE_DIR/${WID}.released"
              msg "Released (stub)."
            else
              msg "Not released."
            fi
          else
            msg "ID not found."
          fi
        fi
        ;;
      6) return;;
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
        RES=$(tail -n 10 "$STATE_DIR/accounts.db" 2>/dev/null)
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
        msg "OFAC check noted (manual process—retain paper evidence)."
        ;;
      2)
        ask_input "CTR Filing" "Transaction Reference / Notes:" "" || continue
        REF=$(cat "$TMP.in")
        log_op "CTR" "Paper CTR filed for: $REF"
        msg "CTR filing logged (paper form mailed to FinCEN)."
        ;;
      3)
        TAIL=$(tail -n 30 "$LOG_DIR/ops.log" 2>/dev/null)
        [ -z "$TAIL" ] && TAIL="No log entries."
        "$DIALOG" --backtitle "$BACKTITLE" --title "Audit Log (last 30)" --msgbox "$TAIL" 20 80
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
        msg "Simulated transmission of $CNT outgoing ACH files."
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
FAILS=0
while :; do
  ask_input "Access Code" "Enter access code (or press Enter to continue):" "" || exit 0
  CODE=$(cat "$TMP.in")

  # Empty = proceed without Special Projects (not a failure)
  if [ -z "$CODE" ]; then
    break
  fi

  if [ "$CODE" = "TPS" ]; then
    SPECIAL_UNLOCK="yes"
    log_op "SECURITY" "Special Projects menu unlocked"
    msg "Access granted.\nWelcome to Special Projects, Peter."
    break
  else
    FAILS=$(($FAILS + 1))
    log_op "SECURITY" "Failed unlock attempt ($FAILS) with code: $CODE"
    if [ $FAILS -ge 3 ]; then
      lumbergh_lockout
    else
      msg "Access code incorrect.\nThat'd be great if you could try again (attempt $FAILS of 3)."
    fi
  fi
done

main_menu

