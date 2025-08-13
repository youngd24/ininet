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
      --menu "Totally normal internal tools" 18 70 9 \
      1 "Configure Rounding Error Parameters" \
      2 "Run Daily Skim Job" \
      3 "Deposit Skim Funds to Slush Account" \
      4 "Generate Fake Audit Report" \
      5 "Reset Stapler Quest State" \
      99 "Return to Main Menu" \
      3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    case "$CHOICE" in
      1) configure_rounding_error;;
      2) run_daily_skim;;
      3) deposit_skim_funds;;
      4) generate_fake_audit;;
      5) reset_stapler_quest;;
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
# Office Space Easter Egg Integration
# -----------------------------
# This function occasionally shows Office Space themed messages
# after the stapler quest is completed
maybe_show_office_space_message() {
  local context="$1"
  
  # Only show if stapler quest is completed
  if [ -f "$PROJECT_DIR/stapler_found.flag" ]; then
    # 1 in 20 chance to show Office Space message
    if [ $((RANDOM % 20)) -eq 0 ]; then
      case "$context" in
        "ach_error")
          office_space_error "paper_jam" "ACH processing failed due to paper jam.\n\nPlease check the document feeder for Milton's stapler."
          ;;
        "wire_error")
          office_space_error "tps_report" "Wire transfer failed.\n\nTPS report missing from wire queue.\n\nDid you get the memo about the TPS reports?"
          ;;
        "compliance_error")
          office_space_error "stapler_related" "Compliance check failed.\n\nMilton says this is related to his stapler being moved.\n\n'I had it set up exactly the way I like it!'"
          ;;
        "general_error")
          office_space_error "paper_jam" "System error detected.\n\nMilton suggests checking for paper jams.\n\n'They better not touch my stapler!'"
          ;;
      esac
    fi
  fi
}

# Reset stapler quest state
reset_stapler_quest() {
  if [ -f "$PROJECT_DIR/stapler_found.flag" ]; then
    if confirm "Reset Stapler Quest" "Are you sure you want to reset the stapler quest?\n\nThis will allow someone to play the quest again.\n\nMilton will lose his stapler again!"; then
      rm -f "$PROJECT_DIR/stapler_found.flag"
      log_op "EASTER_EGG" "Stapler quest state reset by user"
      msg "Stapler quest state has been reset.\n\nMilton's red Swingline stapler is missing again!\n\nSomeone can now enter 'Milton' as the access code to start the quest."
    fi
  else
    msg "Stapler quest has not been completed yet.\n\nNo state to reset."
  fi
}

# -----------------------------
# Stapler Quest (Hidden Easter Egg)
# -----------------------------
stapler_quest() {
  local quest_complete="no"
  local attempts=0
  
  # Check if quest has been completed before
  if [ -f "$PROJECT_DIR/stapler_found.flag" ]; then
    quest_complete="yes"
  fi
  
  if [ "$quest_complete" = "yes" ]; then
    "$DIALOG" --backtitle "$BACKTITLE" --title "Stapler Quest" \
      --msgbox "You've already found Milton's red Swingline stapler!\n\n\
It was in the basement, next to the TPS reports.\n\n\
Milton says thanks for finding it. He was getting really upset." 12 70
    return
  fi
  
  while [ "$quest_complete" = "no" ] && [ $attempts -lt 10 ]; do
    attempts=$((attempts + 1))
    
    CHOICE=$("$DIALOG" --clear --backtitle "$BACKTITLE" --title "Where to search?" \
      --menu "Search for Milton's stapler (Attempt $attempts/10)" 18 70 8 \
      1 "ACH Processing Department" \
      2 "Wire Transfer Office" \
      3 "Compliance & Risk" \
      4 "Customer Service" \
      5 "Back Office Operations" \
      6 "The Basement" \
      7 "Lumbergh's Office" \
      99 "Give up" \
      3>&1 1>&2 2>&3)
    
    [ $? -ne 0 ] && continue
    
    case "$CHOICE" in
      1) # ACH Processing
        "$DIALOG" --backtitle "$BACKTITLE" --title "ACH Department" \
          --msgbox "You search through the ACH processing area...\n\n\
Lots of paperwork, but no stapler here.\n\n\
'Have you seen my stapler?' asks a voice from the next cubicle.\n\n\
That's Milton! He sounds really upset." 12 70
        ;;
      2) # Wire Transfer Office
        "$DIALOG" --backtitle "$BACKTITLE" --title "Wire Transfer Office" \
          --msgbox "You check the wire transfer office...\n\n\
Nothing but wire forms and confirmation slips.\n\n\
'They took my stapler!' Milton yells from across the room.\n\n\
'Who took it?' you ask.\n\n\
'I don't know, but they better not touch it!'" 12 70
        ;;
      3) # Compliance & Risk
        "$DIALOG" --backtitle "$BACKTITLE" --title "Compliance & Risk" \
          --msgbox "You search through compliance files...\n\n\
Lots of audit reports and risk assessments.\n\n\
'It's a Swingline stapler!' Milton explains.\n\n\
'It's not like it's a big deal or anything.'\n\n\
But you can tell it really is a big deal to him." 12 70
        ;;
      4) # Customer Service
        "$DIALOG" --backtitle "$BACKTITLE" --title "Customer Service" \
          --msgbox "You check customer service...\n\n\
'Have you seen a red Swingline stapler?' you ask.\n\n\
'Oh, the red one?' says the customer service rep.\n\n\
'Yeah, that's the one!' you say excitedly.\n\n\
'No, sorry. Haven't seen it.'\n\n\
Darn it!" 12 70
        ;;
      5) # Back Office Operations
        "$DIALOG" --backtitle "$BACKTITLE" --title "Back Office Operations" \
          --msgbox "You search through back office operations...\n\n\
'It's my stapler!' Milton insists.\n\n\
'I had it set up exactly the way I like it.'\n\n\
'And then they moved my desk to storage room B.'\n\n\
'And I was told that I could set it up any way I wanted to.'\n\n\
'So I did.'" 12 70
        ;;
      6) # The Basement
        "$DIALOG" --backtitle "$BACKTITLE" --title "The Basement" \
          --msgbox "You head down to the basement...\n\n\
It's dark and musty down here.\n\n\
You see some old TPS reports stacked in a corner.\n\n\
And there it is! Milton's red Swingline stapler!\n\n\
It's sitting right next to the TPS reports, just like in the movie!\n\n\
You found it!" 15 70
        
        # Quest completed!
        quest_complete="yes"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Stapler found by user" > "$PROJECT_DIR/stapler_found.flag"
        log_op "EASTER_EGG" "Milton's stapler found in basement"
        
        "$DIALOG" --backtitle "$BACKTITLE" --title "Quest Complete!" \
          --msgbox "🎉 CONGRATULATIONS! 🎉\n\n\
You found Milton's red Swingline stapler!\n\n\
It was in the basement, next to the TPS reports.\n\n\
Milton is so happy! He says:\n\n\
'Thank you! Thank you! I was going crazy without it!'\n\n\
You've unlocked the 'Office Space Mode' easter egg!\n\n\
Now when you encounter certain errors, you might see\n\
special Office Space themed messages..." 18 70
        ;;
      7) # Lumbergh's Office
        "$DIALOG" --backtitle "$BACKTITLE" --title "Lumbergh's Office" \
          --msgbox "You check Lumbergh's office...\n\n\
'Yeah... if you could go ahead and not look through my office,\n\
that'd be great. M'kay?'\n\n\
Lumbergh doesn't seem to have the stapler either.\n\n\
'And I'm gonna need you to go ahead and come in on Saturday.\n\
M'kay?'\n\n\
Great, now you have to work Saturday." 15 70
        ;;
      99) # Give up
        "$DIALOG" --backtitle "$BACKTITLE" --title "Quest Abandoned" \
          --msgbox "You decide to give up the search.\n\n\
'Fine! Fine! I'll just burn the building down!' Milton yells.\n\n\
'Calm down, Milton!' you say.\n\n\
'No! I'm serious this time!'\n\n\
Maybe you should try again later..." 12 70
        return
        ;;
    esac
  done
  
  if [ $attempts -ge 10 ] && [ "$quest_complete" = "no" ]; then
    "$DIALOG" --backtitle "$BACKTITLE" --title "Quest Failed" \
      --msgbox "You've searched everywhere but couldn't find the stapler!\n\n\
Milton is getting really upset now.\n\n\
'I'm gonna burn the building down!' he threatens.\n\n\
'Wait, Milton! Let me try one more time!' you plead.\n\n\
'No! I'm serious this time!'\n\n\
Maybe you should try again later..." 15 70
  fi
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
        66 "Special Projects" \
        99 "Exit"  \
        3>&1 1>&2 2>&3) || exit 0

      case "$CHOICE" in
        1) customer_menu;;
        2) payments_menu;;
        3) statements_menu;;
        4) compliance_menu;;
        5) ops_menu;;
        66) special_projects_menu;;
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
  "Milton")
    log_op "SECURITY" "Stapler quest triggered via Milton access code"
    msg "Milton's red Swingline stapler has gone missing!\n\n\
He's getting really upset about it.\n\n\
Can you help him find it?\n\n\
Press OK to begin your quest..."
    stapler_quest
    ;;
  "911")
    milton_lockdown
    ;;
  *)
    [ -n "$CODE" ] && log_op "SECURITY" "Non-special access code entered; proceeding normally"
    ;;
esac

main_menu
