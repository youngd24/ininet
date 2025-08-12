#!/usr/local/bin/bash
# Wire Transfer Module for ININET Banking System
# Solaris 7 + bash 4.1.0 + dialog 1.0  |  Ubuntu 24 + bash 5.2 + dialog 1.3

# Source core functions
# Note: This will be sourced from the main script, so core.sh is already available

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
    [ -z "$pat" ] && continue
    case "$pat" in \#*) continue;; esac
    pat_upper=$(to_upper "$pat")
    echo "$name_upper" | $GREP -F -i "$pat_upper" >/dev/null 2>&1 && return 1
  done < "$OFAC_LIST"
  return 0
}

print_fedwire_form() {
  local id="$1" path="$WIRE_FORMS/${id}.txt" hv="NO"
  if compare_money_ge "$AMT" "$HIGH_VALUE_THRESHOLD"; then hv="YES"; fi
  cat > "$path" <<EOF
ININET WIRE TRANSFER REQUEST (Fedwire Stub)
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
# Wire Entry Function
# -----------------------------
wire_entry() {
  ask_input "Wire Entry" "Debit Account:" "" || return 1; DACC=$(cat "$TMP.in")
  ask_input "Wire Entry" "Credit Name:" "" || return 1; CNAME=$(cat "$TMP.in")
  ask_input "Wire Entry" "Credit ABA (or SWIFT for intl):" "" || return 1; CABA=$(cat "$TMP.in")
  ask_input "Wire Entry" "Credit Account:" "" || return 1; CACC=$(cat "$TMP.in")
  ask_input "Wire Entry" "Amount (USD):" "" || return 1; AMT=$(cat "$TMP.in")
  [ "$AMT" = "911" ] && milton_lockdown
  ask_input "Wire Entry" "Type (DOMESTIC/INTERNATIONAL):" "DOMESTIC" || return 1; TYPE=$(to_upper "$(cat "$TMP.in")")
  ask_input "Wire Entry" "Memo / Reference:" "" || return 1; MEMO=$(cat "$TMP.in")
  ask_input "Wire Entry" "Requested Date (YYYY-MM-DD) or blank for today:" "$(date '+%Y-%m-%d')" || return 1; REQDATE=$(cat "$TMP.in")
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
}

# -----------------------------
# Wire Review and Release Function
# -----------------------------
wire_review_release() {
  PENDING=$(list_pending_ids)
  if [ -z "$PENDING" ]; then msg "No pending wires."; return 1; fi
  ask_input "Release Wire" "Enter pending wire ID to release (or CANCEL):\n\n$(echo "$PENDING")" "" || return 1
  WID=$(cat "$TMP.in")
  [ "$WID" = "CANCEL" ] && return 1
  FILE="$WIRE_QUEUE/$WID"
  if [ ! -f "$FILE" ]; then msg "ID not found."; return 1; fi
  load_wire_file "$FILE"
  ask_input "Dual Control" "Enter Approver ID (must differ from Maker '$MAKER'):" "" || return 1
  APPROVER=$(cat "$TMP.in")
  if [ "$APPROVER" = "$MAKER" ]; then
    msg "Approver cannot be the same as Maker."
    return 1
  fi
  SUMMARY="Release $WID?\n\nDebit: $DACC\nCredit: $CNAME ($CABA/$CACC)\nAmount: \$$AMT\nType: $TYPE\nMemo: ${MEMO:-N/A}\nOFAC: $OFAC\nMaker: $MAKER\nApprover: $APPROVER"
  if [ "$OFAC" = "REVIEW" ]; then
    confirm "$SUMMARY\n\nOFAC flagged for REVIEW. Override and proceed?"
    [ $? -ne 0 ] && { msg "Release aborted."; return 1; }
  else
    confirm "$SUMMARY"
    [ $? -ne 0 ] && { msg "Not released."; return 1; }
  fi
  if compare_money_ge "$AMT" "$HIGH_VALUE_THRESHOLD"; then
    confirm "High-value wire (>= \$$HIGH_VALUE_THRESHOLD). Confirm release again?"
    [ $? -ne 0 ] && { msg "Not released."; return 1; }
  fi
  STATUS="RELEASED"
  save_wire_file "$FILE"
  mv "$FILE" "$WIRE_RELEASED/${WID}.released"
  log_op "WIRE" "Released $WID (maker=$MAKER approver=$APPROVER ofac=$OFAC)"
  log_wire "$WID" "RELEASED" "approver=$APPROVER"
  FORM_PATH=$(print_fedwire_form "$WID")
  msg "Released $WID.\nFedwire stub saved:\n$FORM_PATH"
}

# -----------------------------
# Wire Amend Function
# -----------------------------
wire_amend() {
  PENDING=$(list_pending_ids)
  if [ -z "$PENDING" ]; then msg "No pending wires to amend."; return 1; fi
  ask_input "Amend Wire" "Enter pending wire ID to amend (or CANCEL):\n\n$(echo "$PENDING")" "" || return 1
  WID=$(cat "$TMP.in")
  [ "$WID" = "CANCEL" ] && return 1
  FILE="$WIRE_QUEUE/$WID"
  if [ ! -f "$FILE" ]; then msg "ID not found."; return 1; fi
  load_wire_file "$FILE"
  ask_input "Amend $WID" "Beneficiary Name:" "$CNAME" || return 1; CNAME=$(cat "$TMP.in")
  ask_input "Amend $WID" "Credit ABA/SWIFT:" "$CABA" || return 1; CABA=$(cat "$TMP.in")
  ask_input "Amend $WID" "Credit Account:" "$CACC" || return 1; CACC=$(cat "$TMP.in")
  ask_input "Amend $WID" "Amount (USD):" "$AMT" || return 1; AMT=$(cat "$TMP.in")
  [ "$AMT" = "911" ] && milton_lockdown
  ask_input "Amend $WID" "Type (DOMESTIC/INTERNATIONAL):" "$TYPE" || return 1; TYPE=$(to_upper "$(cat "$TMP.in")")
  ask_input "Amend $WID" "Memo / Reference:" "$MEMO" || return 1; MEMO=$(cat "$TMP.in")
  ask_input "Amend $WID" "Requested Date (YYYY-MM-DD):" "$REQDATE" || return 1; REQDATE=$(cat "$TMP.in")
  TS="$(date '+%Y-%m-%d %H:%M:%S')"
  OFAC="PASS"; if ! ofac_scan_name "$CNAME"; then OFAC="REVIEW"; fi
  STATUS="PENDING"
  save_wire_file "$FILE"
  log_op "WIRE" "Amended $WID (OFAC=$OFAC)"
  log_wire "$WID" "AMENDED" "ofac=$OFAC; amt=$AMT; type=$TYPE"
  msg "$WID amended.\nOFAC: $OFAC"
}

# -----------------------------
# Wire Cancel Function
# -----------------------------
wire_cancel() {
  PENDING=$(list_pending_ids)
  if [ -z "$PENDING" ]; then msg "No pending wires to cancel."; return 1; fi
  ask_input "Cancel Wire" "Enter pending wire ID to cancel (or CANCEL):\n\n$(echo "$PENDING")" "" || return 1
  WID=$(cat "$TMP.in")
  [ "$WID" = "CANCEL" ] && return 1
  FILE="$WIRE_QUEUE/$WID"
  if [ ! -f "$FILE" ]; then msg "ID not found."; return 1; fi
  ask_input "Cancel Reason" "Enter reason for cancellation:" "" || return 1
  REASON=$(cat "$TMP.in")
  load_wire_file "$FILE"
  STATUS="CANCELED"
  save_wire_file "$FILE"
  mv "$FILE" "$WIRE_CANCELED/${WID}.canceled"
  log_op "WIRE" "Canceled $WID (reason: $REASON)"
  log_wire "$WID" "CANCELED" "reason=$REASON"
  msg "Canceled $WID.\nReason: $REASON"
}

# -----------------------------
# Wire Print Form Function
# -----------------------------
wire_print_form() {
  ask_input "Print Form" "Enter wire ID to print stub (pending or released ID accepted):" "" || return 1
  WID=$(cat "$TMP.in")
  FILE="$WIRE_QUEUE/$WID"
  [ -f "$FILE" ] || FILE="$WIRE_RELEASED/${WID}.released"
  if [ ! -f "$FILE" ]; then msg "ID not found in pending or released archive."; return 1; fi
  load_wire_file "$FILE"
  PATH_OUT=$(print_fedwire_form "$WID")
  msg "Form written to:\n$PATH_OUT"
}

# -----------------------------
# Wire History Function
# -----------------------------
wire_history() {
  _H=$($TAILBIN -n 40 "$WIRE_HISTORY" 2>/dev/null)
  [ -z "$_H" ] && _H="No wire history yet."
  "$DIALOG" --backtitle "$BACKTITLE" --title "Wire History (last 40)" --msgbox "$_H" 20 80
}
