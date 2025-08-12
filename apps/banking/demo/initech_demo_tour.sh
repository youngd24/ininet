#!/usr/local/bin/bash
# INITECH Banking System - Quick Demo Tour
# Solaris 7 friendly, no dependencies beyond /usr/local/bin/bash
#
# What it does:
#  - Seeds/refreshes demo data (safe to re-run)
#  - Opens a cheeky new account
#  - Queues a fake NACHA file
#  - Drops a pending wire (non-911!) to PC LOAD LETTER LLC
#  - Sets rounding error + logs a "daily skim"
#  - Optionally launches the TUI at the end

DATA_ROOT="/export/banking"
LOG_DIR="$DATA_ROOT/log"
ACH_INBOX="$DATA_ROOT/ach/incoming"
ACH_OUTBOX="$DATA_ROOT/ach/outgoing"
WIRE_QUEUE="$DATA_ROOT/wires/pending"
DOC_STORE="$DATA_ROOT/docs"
STATE_DIR="$DATA_ROOT/state"
PROJECT_DIR="$DATA_ROOT/special_projects"

TUI="./initech_bank_mvp.sh"   # Adjust path if needed

say() { printf "%s\n" "$*"; }
pause() { sleep 1; }

# Ensure folders
mkdir -p "$LOG_DIR" "$ACH_INBOX" "$ACH_OUTBOX" "$WIRE_QUEUE" "$DOC_STORE" "$STATE_DIR" "$PROJECT_DIR"

# Seed baseline if empty
if [ ! -s "$STATE_DIR/accounts.db" ]; then
  say "[*] No accounts found — seeding baseline cast…"
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

# Always ensure logs exist
[ -f "$LOG_DIR/ops.log" ] || : > "$LOG_DIR/ops.log"

ts() { date '+%Y-%m-%d %H:%M:%S'; }

say "[*] Opening a totally legit new account: TPS Consulting LLC…"
echo "TPS Consulting LLC|12-0000000|ANALYSIS|19990316" >> "$STATE_DIR/accounts.db"
echo "$(ts) | ACCOUNT | Open requested: TPS Consulting LLC / 12-0000000 / ANALYSIS" >> "$LOG_DIR/ops.log"
pause

say "[*] Queuing an outgoing ACH file for vendors…"
echo "NACHA BATCH (demo) OUTGOING — vendors for TPS Consulting LLC." > "$ACH_OUTBOX/ACH_OUT_VENDORS_19990316.nacha"
echo "$(ts) | ACH | Queued for send: ACH_OUT_VENDORS_19990316.nacha" >> "$LOG_DIR/ops.log"
pause

say "[*] Dropping a pending wire to PC LOAD LETTER LLC (not 911, we like our terminals unlocked)…"
WIRE_ID="WIRE.$(date '+%Y%m%d%H%M%S').4242"
cat > "$WIRE_QUEUE/$WIRE_ID" <<'EOF'
DACC=0099001122|CNAME=PC LOAD LETTER LLC|CABA=026009593|CACC=0007771337|AMT=42.00|TS=1999-03-16 10:15:00
EOF
echo "$(ts) | WIRE | Entered $WIRE_ID for review" >> "$LOG_DIR/ops.log"
pause

say "[*] Setting Peter's rounding error to 0.25 cents and running the Daily Skim…"
echo "0.25" > "$PROJECT_DIR/rounding.cfg"
echo "$(ts) | PROJECT | Set rounding error to 0.25 cents" >> "$LOG_DIR/ops.log"
echo "$(ts) | PROJECT | Daily skim executed (nothing suspicious here)" >> "$LOG_DIR/ops.log"
pause

say "[*] Dropping a couple of documents into the 'vault'…"
echo "Signature Card - TPS Consulting LLC (signed with a blue Bic, very official)" > "$DOC_STORE/sigcard_tps.txt"
echo "Fax: Wire Authorization - 'Yeahhhh' cover sheet attached" > "$DOC_STORE/wire_fax_tps.txt"
pause

say
say "============================================================"
say " Demo prep complete!"
say " What to show in the TUI:"
say "  • Payments → ACH: Outbox should show ACH_OUT_VENDORS_19990316.nacha"
say "  • Payments → Wires: Review/Release should list $WIRE_ID"
say "  • Account Info & Statements: EoD shows recent account opens"
say "  • Fraud, Risk & Compliance → Audit Log: shows 'PROJECT' and 'ACH' entries"
say "  • (Secret) Enter 'TPS' at startup to unlock Special Projects"
say "     - Configure Rounding, Run Daily Skim, Deposit to 'PC LOAD LETTER LLC'"
say "  • Type '911' as a wire amount to trigger MILTON lockdown (for laughs)"
say "============================================================"
say

# Offer to launch the TUI
if [ -x "$TUI" ]; then
  say -n "Launch the INITECH TUI now? [y/N]: "
  # shellcheck disable=SC2162
  read ans
  case "$ans" in
    y|Y) exec "$TUI" ;;
    *)   say "OK! Run it later with: $TUI" ;;
  esac
else
  say "[!] Could not find executable TUI at: $TUI"
  say "    Start it manually after seeding, e.g.: ./initech_bank_mvp.sh"
fi

