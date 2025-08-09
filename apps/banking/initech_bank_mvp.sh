#!/usr/local/bin/bash
TITLE="INITECH Financial Systems"
BACKTITLE="INITECH - Banking Dashboard"
DATA_ROOT="/export/banking"
DIALOG="/usr/local/bin/dialog"; [ -x "$DIALOG" ] || DIALOG="/usr/bin/dialog"

README_FILE="./README.txt"
[ -f "$README_FILE" ] || README_FILE="$DATA_ROOT/README.txt"

get_term_size() {
  L=$(tput lines 2>/dev/null); C=$(tput cols 2>/dev/null)
  case "$L" in ''|*[!0-9]*) L=24;; esac
  case "$C" in ''|*[!0-9]*) C=80;; esac
  TB_H=$(( L - 2 ));  [ "$TB_H" -lt 10 ] && TB_H=10
  TB_W=$(( C - 4 ));  [ "$TB_W" -lt 60 ] && TB_W=60
}

view_readme() {
  if [ -f "$README_FILE" ]; then
    get_term_size
    "$DIALOG" --backtitle "$BACKTITLE"               --title "INITECH Banking – Operations Manual"               --textbox "$README_FILE" "$TB_H" "$TB_W"
  else
    "$DIALOG" --backtitle "$BACKTITLE" --title "$TITLE"               --msgbox "README not found. Looked for:\n  ./README.txt\n  $DATA_ROOT/README.txt" 10 70
  fi
}

main_menu() {
    while true; do
        CHOICE=$("$DIALOG" --clear --backtitle "$BACKTITLE" --title "$TITLE"             --menu "Main Menu" 18 70 10             1 "Customer & Account Management"             2 "Payments (ACH + Wires)"             3 "Account Info & Statements"             4 "Fraud, Risk & Compliance"             5 "Back Office Operations"             6 "View README / Operations Manual"             7 "Exit"             3>&1 1>&2 2>&3) || exit 0

        case "$CHOICE" in
            1) "$DIALOG" --msgbox "Customer Menu (demo)" 8 40;;
            2) "$DIALOG" --msgbox "Payments Menu (demo)" 8 40;;
            3) "$DIALOG" --msgbox "Statements Menu (demo)" 8 40;;
            4) "$DIALOG" --msgbox "Compliance Menu (demo)" 8 40;;
            5) "$DIALOG" --msgbox "Ops Menu (demo)" 8 40;;
            6) view_readme;;
            7) clear; exit 0;;
        esac
    done
}

main_menu
