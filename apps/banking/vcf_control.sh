#!/usr/local/bin/bash
DATA_ROOT="/export/banking"
LOG_DIR="$DATA_ROOT/log"
ACH_INBOX="$DATA_ROOT/ach/incoming"
ACH_OUTBOX="$DATA_ROOT/ach/outgoing"
WIRE_QUEUE="$DATA_ROOT/wires/pending"
DOC_STORE="$DATA_ROOT/docs"
STATE_DIR="$DATA_ROOT/state"
PROJECT_DIR="$DATA_ROOT/special_projects"
TUI="./initech_bank_mvp.sh"
DIALOG="/usr/local/bin/dialog"; [ -x "$DIALOG" ] || DIALOG="/usr/bin/dialog"

say() { printf "%s\n" "$*"; }
pause() { sleep 1; }

ensure_dirs() {
  mkdir -p "$LOG_DIR" "$ACH_INBOX" "$ACH_OUTBOX" "$WIRE_QUEUE" "$DOC_STORE" "$STATE_DIR" "$PROJECT_DIR"
  [ -f "$LOG_DIR/ops.log" ] || : > "$LOG_DIR/ops.log"
}

seed_baseline() {
  ensure_dirs
  if [ ! -s "$STATE_DIR/accounts.db" ]; then
    cat > "$STATE_DIR/accounts.db" <<'EOF'
Peter Gibbons|123-45-6789|CHK|19990312
Samir Nagheenanajar|111-22-3333|CHK|19990312
Michael Bolton|222-33-4444|SAV|19990312
Milton Waddams|333-44-5555|CHK|19981201
Bill Lumbergh|444-55-6666|ANALYSIS|19990115
Joanna|555-66-7777|CHK|19990301
EOF
  fi
  echo "[✓] Baseline seeded."
}

reset_baseline() {
  ensure_dirs
  rm -f "$LOG_DIR"/* "$ACH_INBOX"/* "$ACH_OUTBOX"/* "$WIRE_QUEUE"/* "$DOC_STORE"/* "$PROJECT_DIR"/* 2>/dev/null
  rm -f "$STATE_DIR/accounts.db"
  seed_baseline
  say "[✓] Reset complete."
}

launch_tui() {
  if [ -x "$TUI" ]; then exec "$TUI"; else say "TUI not found"; fi
}

while :; do
  if [ -x "$DIALOG" ]; then
    CHOICE=$("$DIALOG" --clear --backtitle "INITECH - VCF Control" --title "Control Panel"       --menu "Pick an action" 18 70 10       1 "Reset to Baseline"       2 "Seed Baseline Only"       3 "Launch INITECH TUI"       4 "Quit"       3>&1 1>&2 2>&3) || exit 0
  else
    echo "1) Reset to Baseline"
    echo "2) Seed Baseline Only"
    echo "3) Launch INITECH TUI"
    echo "4) Quit"
    read CHOICE
  fi
  case "$CHOICE" in
    1) reset_baseline;;
    2) seed_baseline;;
    3) launch_tui;;
    4) exit 0;;
  esac
done
