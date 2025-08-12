#!/usr/local/bin/bash
# Back Office Module for ININET Banking System
# Solaris 7 + bash 4.1.0 + dialog 1.0  |  Ubuntu 24 + bash 5.2 + dialog 1.3

# Source core functions
# Note: This will be sourced from the main script, so core.sh is already available

# -----------------------------
# Back Office Functions
# -----------------------------

# End-of-Day Posting & Reconciliation (stub)
eod_posting() {
  log_op "EOD" "EoD posting & reconciliation completed (stub)."
  msg "EoD posting & reconciliation simulated."
}

# Document Storage (paper/microfilm placeholder)
document_storage() {
  msg "Physical documents to be filed; optical/microfilm index simulated at: $DOC_STORE"
}

# -----------------------------
# Y2K Readiness & Conversion Functions
# -----------------------------

# Report suspicious (non-YYYYMMDD) dates in accounts.db (col 4)
y2k_report_accounts() {
  local f="${STATE_DIR:-/export/banking/state}/accounts.db"
  if [ ! -s "$f" ]; then echo "(no accounts.db)"; return; fi
  local _AWK="${AWK:-awk}"
  "$_AWK" -F'|' '
    function iso(d){ return (d ~ /^[0-9]{8}$/) }
    {
      d=$4
      if (!iso(d) && d != "") {
        printf("Line %d: %s\n", NR, $0)
      }
    }
  ' "$f"
}

# Convert accounts.db in place (with .bak), normalizing date column
y2k_convert_accounts() {
  local f="${STATE_DIR:-/export/banking/state}/accounts.db"
  local tmp="${f}.tmp" bak="${f}.bak"
  [ -f "$f" ] || { echo "missing accounts.db"; return 1; }
  cp "$f" "$bak" || return 1
  : > "$tmp" || return 1
  while IFS='|' read -r c1 c2 c3 c4 rest; do
    if [ -n "$c4" ]; then
      nd=$(normalize_date_ymd "$c4")
      if [ -n "$nd" ] && validate_yyyymmdd "$nd"; then
        c4="$nd"
      fi
    fi
    if [ -n "$rest" ]; then
      printf "%s|%s|%s|%s|%s\n" "$c1" "$c2" "$c3" "$c4" "$rest" >> "$tmp"
    else
      printf "%s|%s|%s|%s\n" "$c1" "$c2" "$c3" "$c4" >> "$tmp"
    fi
  done < "$f"
  mv "$tmp" "$f"
}

# Quick grep for 2-digit years in NACHA-like files (ACH inbox/outbox)
y2k_scan_ach() {
  local in="${ACH_INBOX:-${STATE_DIR:-/export/banking/state}/ach/inbox}"
  local out="${ACH_OUTBOX:-${STATE_DIR:-/export/banking/state}/ach/outbox}"
  local _GREP="${GREP:-grep}"
  local hits
  hits=$("$_GREP" -E -n '([0-9]{2}[-/][0-9]{2}[-/][0-9]{2}|[0-9]{6})' "$in"/* "$out"/* 2>/dev/null || true)
  [ -n "$hits" ] && echo "$hits" || echo "(no suspicious 2-digit date patterns found)"
}

# Leap-day 2000 invariants test
y2k_leapday_selftest() {
  if validate_yyyymmdd "20000229"; then
    echo "PASS: 2000-02-29 valid (leap century)"
  else
    echo "FAIL: 2000-02-29 should be valid"
  fi
  if validate_yyyymmdd "19000229"; then
    echo "FAIL: 1900-02-29 should be invalid"
  else
    echo "PASS: 1900-02-29 invalid"
  fi
}

# Simulate date rollover using FAKE_TODAY=YYYYMMDD (session only)
y2k_rollover_sim() {
  local day="$1"
  if [ -z "$day" ]; then
    echo "Usage: y2k_rollover_sim YYYYMMDD"
    return 1
  fi
  FAKE_TODAY="$day" echo "Simulated date set for this run: $day"
}

# -----------------------------
# Special Projects (Peter's secret menu)
# -----------------------------

# Configure Rounding Error Parameters
configure_rounding_error() {
  ask_input "Rounding Error" "Enter max rounding error (in cents):" "0.5" || return 1
  VAL=$(cat "$TMP.in")
  echo "$VAL" > "$PROJECT_DIR/rounding.cfg"
  log_op "PROJECT" "Set rounding error to $VAL cents"
  msg "Rounding error set to $VAL cents.\nAs Peter says, 'It's just fractions of a cent...'"
}

# Run Daily Skim Job
run_daily_skim() {
  log_op "PROJECT" "Daily skim executed"
  msg "Daily skim complete.\nPennies redirected to special ledger.\nLumbergh will never notice."
}

# Deposit Skim Funds to Slush Account
deposit_skim_funds() {
  log_op "PROJECT" "Slush account credited"
  msg "Funds moved to 'PC LOAD LETTER LLC' account.\nLooks legit."
}

# Generate Fake Audit Report
generate_fake_audit() {
  log_op "PROJECT" "Fake audit generated"
  msg "Audit report created.\nOmitted 'Special Projects' line item as requested."
}
