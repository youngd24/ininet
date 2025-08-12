#!/usr/local/bin/bash
# Optional portable launcher: uncomment if you want auto-fallback on Linux.
# [ -n "$BASH_VERSION" ] || exec /usr/bin/env bash "$0" "$@"
##############################################################################
# INITECH BANKING SYSTEM (Late 90's MVP + Office Space gag) - MODULAR VERSION
# Solaris 7 + bash 4.1.0 + dialog 1.0  |  Ubuntu 24 + bash 5.2 + dialog 1.3
#
# This is the modular version of the original monolithic script.
# All functionality has been split into logical modules in the lib/ directory.
##############################################################################

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Source all library modules
. "$LIB_DIR/core.sh"
. "$LIB_DIR/ui.sh"
. "$LIB_DIR/wires.sh"
. "$LIB_DIR/customers.sh"
. "$LIB_DIR/ach.sh"
. "$LIB_DIR/compliance.sh"
. "$LIB_DIR/backoffice.sh"
. "$LIB_DIR/statements.sh"

# -----------------------------
# Menu Functions
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
      99 "Return to Main Menu" \
      3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    case "$CHOICE" in
      1) open_account;;
      2) close_freeze_account;;
      3) manage_signers;;
      4) lookup_customer;;
      99) return;;
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
      99 "Return to Main Menu" \
      3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    case "$CHOICE" in
      1) ach_receive;;
      2) ach_originate;;
      3) ach_returns;;
      4) wire_entry;;
      5) wire_review_release;;
      6) wire_amend;;
      7) wire_cancel;;
      8) wire_print_form;;
      9) wire_history;;
      99) return;;
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
      99 "Return to Main Menu" \
      3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    case "$CHOICE" in
      1) eod_balances;;
      2) monthly_statements;;
      3) commercial_exports;;
      99) return;;
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
      99 "Return to Main Menu" \
      3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    case "$CHOICE" in
      1) ofac_check;;
      2) ctr_filing;;
      3) audit_log;;
      99) return;;
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
      5 "Y2K Readiness & Conversion" \
      99 "Return to Main Menu" \
      3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    case "$CHOICE" in
      1) ach_post_incoming;;
      2) ach_send_outgoing;;
      3) eod_posting;;
      4) document_storage;;
      5) y2k_menu;;
      99) return;;
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
      99 "Return to Main Menu" \
      3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    case "$CHOICE" in
      1) configure_rounding_error;;
      2) run_daily_skim;;
      3) deposit_skim_funds;;
      4) generate_fake_audit;;
      99) return;;
    esac
  done
}

# Y2K Readiness & Conversion Menu
y2k_menu() {
  while :; do
    CHOICE=$("$DIALOG" --clear --backtitle "$BACKTITLE" --title "Y2K Readiness & Conversion" \
      --menu "Pick a function" 20 74 10 \
      1 "Scan accounts.db for risky date formats" \
      2 "Convert accounts.db to YYYYMMDD (makes .bak)" \
      3 "Scan ACH inbox/outbox for 2-digit dates" \
      4 "Leap-Day 2000 Self-Test" \
      5 "Simulate Rollover (set FAKE_TODAY for this session)" \
      99 "Return to Main Menu" \
      3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    case "$CHOICE" in
      1)
        OUT=$(y2k_report_accounts)
        [ -z "$OUT" ] && OUT="(no issues found)"
        "$DIALOG" --backtitle "$BACKTITLE" --title "accounts.db scan" --msgbox "$OUT" 20 80
        ;;
      2)
        if y2k_convert_accounts; then
          "$DIALOG" --backtitle "$BACKTITLE" --title "Conversion" --msgbox "accounts.db normalized (backup saved)." 10 60
        else
          "$DIALOG" --backtitle "$BACKTITLE" --title "Conversion" --msgbox "Conversion failed." 10 60
        fi
        ;;
      3)
        OUT=$(y2k_scan_ach)
        "$DIALOG" --backtitle "$BACKTITLE" --title "ACH date scan" --msgbox "$OUT" 20 80
        ;;
      4)
        OUT=$(y2k_leapday_selftest)
        "$DIALOG" --backtitle "$BACKTITLE" --title "Leap-day test" --msgbox "$OUT" 12 70
        ;;
      5)
        ask_input "Rollover Sim" "Enter simulated date (YYYYMMDD):" "$(date '+%Y%m%d')" || continue
        SD=$(cat "$TMP.in")
        if validate_yyyymmdd "$SD"; then
          y2k_rollover_sim "$SD" >/dev/null
          "$DIALOG" --backtitle "$BACKTITLE" --title "Rollover" --msgbox "For this run, FAKE_TODAY is $SD." 10 60
        else
          "$DIALOG" --backtitle "$BACKTITLE" --title "Rollover" --msgbox "Invalid date." 8 40
        fi
        ;;
      99) return;;
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
	5 "Back Office Operations (Y2K)" \
        6 "Special Projects" \
        99 "Exit"  \
        3>&1 1>&2 2>&3) || exit 0

      case "$CHOICE" in
        1) customer_menu;;
        2) payments_menu;;
        3) statements_menu;;
        4) compliance_menu;;
        5) ops_menu;;
        6) special_projects_menu;;
        99) exit 0;;
      esac
    else
      CHOICE=$("$DIALOG" --clear --backtitle "$BACKTITLE" --title "$TITLE" \
        --menu "Main Menu" 18 70 10 \
        1 "Customer & Account Management" \
        2 "Payments (ACH + Wires)" \
        3 "Account Info & Statements" \
        4 "Fraud, Risk & Compliance" \
        5 "Back Office Operations" \
        99 "Exit"  \
        3>&1 1>&2 2>&3) || exit 0

      case "$CHOICE" in
        1) customer_menu;;
        2) payments_menu;;
        3) statements_menu;;
        4) compliance_menu;;
        5) ops_menu;;
        99) exit 0;;
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
