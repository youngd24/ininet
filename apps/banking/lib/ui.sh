#!/usr/local/bin/bash
# UI Framework for ININET Banking System
# Solaris 7 + bash 4.1.0 + dialog 1.0  |  Ubuntu 24 + bash 5.2 + dialog 1.3

# Source core functions
# Note: This will be sourced from the main script, so core.sh is already available

# -----------------------------
# Dialog Wrapper Functions
# -----------------------------
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

# Office Space themed error messages (only after stapler found)
office_space_error() {
  local error_type="$1"
  local message="$2"
  
  # Check if stapler quest has been completed
  if [ -f "$PROJECT_DIR/stapler_found.flag" ]; then
    case "$error_type" in
      "paper_jam")
        "$DIALOG" --backtitle "$BACKTITLE" --title "Office Space Error" \
          --msgbox "ERROR: Paper jam detected.\n\n\
Please check for red Swingline stapler in document feeder.\n\n\
Milton says this happens when people touch his stapler.\n\n\
$message" 15 70
        ;;
      "tps_report")
        "$DIALOG" --backtitle "$BACKTITLE" --title "Office Space Error" \
          --msgbox "ERROR: TPS Report not found.\n\n\
Did you get the memo about the TPS reports?\n\n\
Yeah, we're putting new coversheets on all the TPS reports\n\
before they go out now.\n\n\
$message" 15 70
        ;;
      "stapler_related")
        "$DIALOG" --backtitle "$BACKTITLE" --title "Office Space Error" \
          --msgbox "ERROR: Stapler-related issue detected.\n\n\
'It's my stapler!' Milton insists.\n\n\
'I had it set up exactly the way I like it.'\n\n\
$message" 12 70
        ;;
      *)
        # Fall back to normal error display
        "$DIALOG" --backtitle "$BACKTITLE" --title "$TITLE" --msgbox "$message" 12 70
        ;;
    esac
  else
    # Normal error display if stapler not found yet
    "$DIALOG" --backtitle "$BACKTITLE" --title "$TITLE" --msgbox "$message" 12 70
  fi
}
