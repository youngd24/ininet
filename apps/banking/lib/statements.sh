#!/usr/local/bin/bash
# Statements Module for ININET Banking System
# Solaris 7 + bash 4.1.0 + dialog 1.0  |  Ubuntu 24 + bash 5.2 + dialog 1.3

# Source core functions
# Note: This will be the main script, so core.sh is already available

# -----------------------------
# Account Info & Statements Functions
# -----------------------------

# End-of-Day Balances (stub view)
eod_balances() {
  RES=$($TAILBIN -n 10 "$STATE_DIR/accounts.db" 2>/dev/null)
  [ -z "$RES" ] && RES="No data yet."
  "$DIALOG" --backtitle "$BACKTITLE" --title "EoD Balances (Demo)" --msgbox "$RES" 18 70
}

# Monthly Statements (paper queue)
monthly_statements() {
  ask_input "Monthly Statements" "Enter Account Number (or ALL):" "ALL" || return 1
  AC=$(cat "$TMP.in")
  log_op "STATEMENTS" "Queued monthly statements for: $AC"
  msg "Statement job queued (paper print workflow stub)."
}

# Commercial Exports (BAI2/fixed-width stub)
commercial_exports() {
  ask_input "Commercial Export" "Customer/Account selector (free text):" "" || return 1
  SEL=$(cat "$TMP.in")
  OUT="$STATE_DIR/export_$(date '+%Y%m%d_%H%M%S').bai2"
  echo "BAI2/FixedWidth placeholder for [$SEL] at $(date)" > "$OUT"
  log_op "EXPORT" "Generated $OUT for $SEL"
  msg "Export created: $OUT"
}
