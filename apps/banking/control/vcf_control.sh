#!/usr/local/bin/bash
##############################################################################
# INITECH VCF CONTROL
# One script to rule the booth: Reset, Seed, Demo Tour, Launch TUI, View Log
# Solaris 7 + bash + (optional) dialog 1.0
##############################################################################

DATA_ROOT="/export/banking"
LOG_DIR="$DATA_ROOT/log"
ACH_INBOX="$DATA_ROOT/ach/incoming"
ACH_OUTBOX="$DATA_ROOT/ach/outgoing"
WIRE_QUEUE="$DATA_ROOT/wires/pending"
DOC_STORE="$DATA_ROOT/docs"
STATE_DIR="$DATA_ROOT/state"
PROJECT_DIR="$DATA_ROOT/special_projects"

TUI="./initech_bank_mvp.sh"  # Adjust path if needed
DIALOG="/usr/local/bin/dialog"; [ -x "$DIALOG" ] || DIALOG="/usr/bin/dialog"

say() { printf "%s\n" "$*"; }
ts() { date '+%Y-%m-%d %H:%M:%S'; }
pause() { sleep 1; }

ensure_dirs() {
  mkdir -p "$LOG_DIR" "$ACH_INBOX" "$ACH_OUTBOX" "$WIRE_QUEUE" "$DOC_STORE" "$STATE_DIR" "$PROJECT_DIR"
  [ -f "$LOG_DIR/ops.log" ] || : > "$LOG_DIR/ops.log"
}

seed_baseline() {
  ensure_dirs
  # Seed accounts if empty
  if [ ! -s "$STATE_DIR/accounts.db" ]; then
    cat > "$STATE_DIR/accounts.db" <<'EOF'
Peter Gibbons|123-45-6789|CHK|19990312
Samir Nagheenanajar|111-22-3333|CHK|19990312
Michael Bolton|222-33-4444|SAV|19990312
Milton Waddams|333-44-5555|CHK|19981201
Bill Lumbergh|444-55-6666|ANALYSIS|19990115
Joanna|555-66-7777|CHK|19990301
Tom Smykowski|666-77-8888|CHK|19990102
Bob Slydell|777-88-9999|CHK|19990210
Bob Porter|888-99-0000|CHK|19990210
Initrode Corp.|23-4567890|ANALYSIS|19981111
Initech Payroll Clearing|98-7654321|ZBA|19990101
PC LOAD LETTER LLC|12-3456789|ESCROW|19990202
EOF
  fi

  # Add a couple of log lines and files so menus aren't empty
  {
    echo "$(ts) | ACCOUNT | Open requested: Peter Gibbons / 123-45-6789 / CHK"
    echo "$(ts) | OFAC | Manual check recorded for: Naga... Naga... (not gonna work here anymore)"
    echo "$(ts) | ACH | Queued for send: ACH_OUT_PAYROLL_19990315.nacha"
    echo "$(ts) | PROJECT | Set rounding error to 0.25 cents"
  } >> "$LOG_DIR/ops.log"

  echo "NACHA BATCH (demo) INCOMING — looks legit." > "$ACH_INBOX/ACH_IN_19990315.nacha"
  echo "NACHA BATCH (demo) OUTGOING — payroll for Initech." > "$ACH_OUTBOX/ACH_OUT_PAYROLL_19990315.nacha"

  # One pending wire
  WI="WIRE.19990315111500.4242"
  cat > "$WIRE_QUEUE/$WI" <<'EOF'
DACC=123456789|CNAME=PC LOAD LETTER LLC|CABA=021000021|CACC=0007771337|AMT=42.00|TS=1999-03-15 11:15:00
EOF

  # Special Projects config + docs
  echo "0.25" > "$PROJECT_DIR/rounding.cfg"
  echo "Signature Card - Peter Gibbons (red stapler imprint faintly visible)" > "$DOC_STORE/sigcard_peter.txt"
  echo "Fax: Wire Authorization Form (coversheet says 'Yeahhhh')" > "$DOC_STORE/wire_fax_joanna.txt"

  say "[✓] Baseline seeded."
}

reset_baseline() {
  ensure_dirs
  # Safety
  if [ "$DATA_ROOT" = "/" ] || [ -z "$DATA_ROOT" ]; then
    say "Refusing to run — DATA_ROOT is unsafe: $DATA_ROOT"; exit 1
  fi

  say "[*] Clearing transient data..."
  rm -f "$LOG_DIR"/* \
        "$ACH_INBOX"/* "$ACH_OUTBOX"/* \
        "$WIRE_QUEUE"/* \
        "$DOC_STORE"/* \
        "$PROJECT_DIR"/* 2>/dev/null

  say "[*] Resetting accounts database..."
  rm -f "$STATE_DIR/accounts.db"

  seed_baseline
  say "[✓] Reset complete."
}

demo_tour() {
  ensure_dirs
  # Open a cheeky account
  echo "TPS Consulting LLC|12-0000000|ANALYSIS|19990316" >> "$STATE_DIR/accounts.db"
  echo "$(ts) | ACCOUNT | Open requested: TPS Consulting LLC / 12-0000000 / ANALYSIS" >> "$LOG_DIR/ops.log"

  # Queue an outgoing ACH
  echo "NACHA BATCH (demo) OUTGOING — vendors for TPS Consulting LLC." > "$ACH_OUTBOX/ACH_OUT_VENDORS_19990316.nacha"
  echo "$(ts) | ACH | Queued for send: ACH_OUT_VENDORS_19990316.nacha" >> "$LOG_DIR/ops.log"

  # Drop a pending non-911 wire
  WIRE_ID="WIRE.$(date '+%Y%m%d%H%M%S').4242"
  cat > "$WIRE_QUEUE/$WIRE_ID" <<'EOF'
DACC=0099001122|CNAME=PC LOAD LETTER LLC|CABA=026009593|CACC=0007771337|AMT=42.00|TS=1999-03-16 10:15:00
EOF
  echo "$(ts) | WIRE | Entered $WIRE_ID for review" >> "$LOG_DIR/ops.log"

  # Configure rounding + run skim
  echo "0.25" > "$PROJECT_DIR/rounding.cfg"
  echo "$(ts) | PROJECT | Set rounding error to 0.25 cents" >> "$LOG_DIR/ops.log"
  echo "$(ts) | PROJECT | Daily skim executed (nothing suspicious here)" >> "$LOG_DIR/ops.log"

  # Docs
  echo "Signature Card - TPS Consulting LLC (signed with a blue Bic, very official)" > "$DOC_STORE/sigcard_tps.txt"
  echo "Fax: Wire Authorization - 'Yeahhhh' cover sheet attached" > "$DOC_STORE/wire_fax_tps.txt"

  say "[✓] Demo tour staged."
}

launch_tui() {
  if [ -x "$TUI" ]; then
    exec "$TUI"
  else
    say "[!] TUI not found or not executable: $TUI"
    say "    Make sure initech_bank_mvp.sh is present and executable."
  fi
}

view_log() {
  ensure_dirs
  if [ -x "$DIALOG" ]; then
    TAIL="$(tail -n 40 "$LOG_DIR/ops.log" 2>/dev/null)"; [ -z "$TAIL" ] && TAIL="(log empty)"
    "$DIALOG" --backtitle "INITECH - VCF Control" --title "Audit Log (last 40)" --msgbox "$TAIL" 22 80
  else
    say "----- Audit Log (last 40) -----"
    tail -n 40 "$LOG_DIR/ops.log" 2>/dev/null || say "(log empty)"
    say "--------------------------------"
  fi
}

# ---------------- Menu ----------------
ensure_dirs

while :; do
  if [ -x "$DIALOG" ]; then
    CHOICE=$("$DIALOG" --clear --backtitle "INITECH - VCF Control" --title "Control Panel" \
      --menu "Pick an action" 18 70 10 \
      1 "Reset to Baseline (wipe & reseed)" \
      2 "Seed Baseline Only" \
      3 "Run Demo Tour (stage jokes)" \
      4 "Launch INITECH TUI" \
      5 "View Audit Log" \
      6 "Quit" \
      3>&1 1>&2 2>&3) || exit 0
  else
    say
    say "=== INITECH VCF CONTROL (no dialog) ==="
    say "1) Reset to Baseline (wipe & reseed)"
    say "2) Seed Baseline Only"
    say "3) Run Demo Tour (stage jokes)"
    say "4) Launch INITECH TUI"
    say "5) View Audit Log"
    say "6) Quit"
    printf "Select: "; read CHOICE
  fi

  case "$CHOICE" in
    1) reset_baseline ;;
    2) seed_baseline ;;
    3) demo_tour ;;
    4) launch_tui ;;
    5) view_log ;;
    6) exit 0 ;;
    *) say "Invalid choice."; pause ;;
  esac
done

