#!/usr/local/bin/bash
# Customer Management Module for ININET Banking System
# Solaris 7 + bash 4.1.0 + dialog 1.0  |  Ubuntu 24 + bash 5.2 + dialog 1.3

# Source core functions
# Note: This will be sourced from the main script, so core.sh is already available

# -----------------------------
# Customer & Account Management Functions
# -----------------------------

# Open Account (branch/manual KYC)
open_account() {
  ask_input "Open Account" "Customer Name:" "" || return 1
  NAME=$(cat "$TMP.in")
  ask_input "Open Account" "SSN / EIN:" "" || return 1
  TAXID=$(cat "$TMP.in")
  ask_input "Open Account" "Product (e.g., CHK, SAV, ANALYSIS):" "CHK" || return 1
  PROD=$(cat "$TMP.in")
  echo "$NAME|$TAXID|$PROD|$(ensure_today_or_default)" >> "$STATE_DIR/accounts.db"
  log_op "ACCOUNT" "Open requested: $NAME / $TAXID / $PROD"
  msg "Open request recorded (paper KYC, signature card, and core entry to be completed)."
}

# Close/Freeze Account
close_freeze_account() {
  ask_input "Close/Freeze" "Account Number:" "" || return 1
  ACCT=$(cat "$TMP.in")
  confirm "Freeze account $ACCT?\n\nSelect Yes to Freeze, No to Close (stub)."
  if [ $? -eq 0 ]; then
    log_op "ACCOUNT" "Freeze requested: $ACCT"
    msg "Freeze request recorded (requires core action)."
  else
    log_op "ACCOUNT" "Close requested: $ACCT"
    msg "Close request recorded (requires core action)."
  fi
}

# Manage Signers / Authorized Users
manage_signers() {
  ask_input "Signers" "Account Number:" "" || return 1
  ACCT=$(cat "$TMP.in")
  ask_input "Signers" "Add or Remove signer? (ADD/REMOVE)" "ADD" || return 1
  ACT=$(cat "$TMP.in")
  ask_input "Signers" "Signer Name:" "" || return 1
  SNAME=$(cat "$TMP.in")
  log_op "SIGNERS" "$ACT signer '$SNAME' on $ACCT"
  msg "Signer change recorded (manual approval path required)."
}

# Lookup Customer / Accounts
lookup_customer() {
  ask_input "Lookup" "Search by Name/TaxID/Acct:" "" || return 1
  Q=$(cat "$TMP.in")
  RES=$($AWK -F'|' -v q="$Q" 'BEGIN{uq=toupper(q)} { if (index(toupper($0), uq)) print }' "$STATE_DIR/accounts.db" 2>/dev/null)
  [ -z "$RES" ] && RES="No matches."
  "$DIALOG" --backtitle "$BACKTITLE" --title "Lookup Results" --msgbox "$RES" 15 70
}
