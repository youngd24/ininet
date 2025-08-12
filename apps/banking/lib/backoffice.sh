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

# Note: Y2K functions have been moved to lib/y2k.sh module

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
