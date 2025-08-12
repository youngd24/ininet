#!/usr/local/bin/bash
# Y2K Readiness & Conversion Module for ININET Banking System
# Solaris 7 + bash 4.1.0 + dialog 1.0  |  Ubuntu 24 + bash 5.2 + dialog 1.3

# Source core functions
# Note: This will be sourced from the main script, so core.sh is already available

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
# Y2K Menu Function
# -----------------------------
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
