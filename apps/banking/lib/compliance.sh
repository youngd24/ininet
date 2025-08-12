#!/usr/local/bin/bash
# Compliance Module for ININET Banking System
# Solaris 7 + bash 4.1.0 + dialog 1.0  |  Ubuntu 24 + bash 5.2 + dialog 1.3

# Source core functions
# Note: This will be sourced from the main script, so core.sh is already available

# -----------------------------
# Compliance Functions
# -----------------------------

# OFAC Check (manual log)
ofac_check() {
  ask_input "OFAC" "Name or Reference to check (manual process in 90s):" "" || return 1
  REF=$(cat "$TMP.in")
  log_op "OFAC" "Manual check recorded for: $REF"
  msg "OFAC check noted (manual process—retain paper evidence).\n\nShared list at: $OFAC_LIST"
}

# CTR Paper Filing (log stub)
ctr_filing() {
  ask_input "CTR Filing" "Transaction Reference / Notes:" "" || return 1
  REF=$(cat "$TMP.in")
  log_op "CTR" "Paper CTR filed for: $REF"
  msg "CTR filing logged (paper form mailed to FinCEN)."
}

# Audit Log (tail view)
audit_log() {
  _LOG=$($TAILBIN -n 30 "$LOG_DIR/ops.log" 2>/dev/null)
  [ -z "$_LOG" ] && _LOG="No log entries."
  "$DIALOG" --backtitle "$BACKTITLE" --title "Audit Log (last 30)" --msgbox "$_LOG" 20 80
}
