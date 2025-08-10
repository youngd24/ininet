#!/usr/local/bin/bash
# Seeds demo data for the INITECH BANKING SYSTEM mockup
# Solaris 7-friendly

DATA_ROOT="/export/banking"
LOG_DIR="$DATA_ROOT/log"
ACH_INBOX="$DATA_ROOT/ach/incoming"
ACH_OUTBOX="$DATA_ROOT/ach/outgoing"
WIRE_QUEUE="$DATA_ROOT/wires/pending"
DOC_STORE="$DATA_ROOT/docs"
STATE_DIR="$DATA_ROOT/state"
PROJECT_DIR="$DATA_ROOT/special_projects"

mkdir -p "$LOG_DIR" "$ACH_INBOX" "$ACH_OUTBOX" "$WIRE_QUEUE" "$DOC_STORE" "$STATE_DIR" "$PROJECT_DIR"

# ---- accounts.db (Name|TaxID|Product|OpenDate YYYYMMDD)
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

# ---- logs with cheeky entries
NOW="$(date '+%Y-%m-%d %H:%M:%S')"
{
  echo "$NOW | ACCOUNT | Open requested: Peter Gibbons / 123-45-6789 / CHK"
  echo "$NOW | ACCOUNT | Open requested: Samir Nagheenanajar / 111-22-3333 / CHK"
  echo "$NOW | OFAC | Manual check recorded for: Naga... Naga... (not gonna work here anymore)"
  echo "$NOW | ACH | Queued for send: ACH_OUT_PAYROLL_19990315.nacha"
  echo "$NOW | ACH_POST | Posted 1 incoming files (stub)."
  echo "$NOW | WIRE | Entered WIRE.19990315111500.4242 for review"
  echo "$NOW | PROJECT | Set rounding error to 0.25 cents"
  echo "$NOW | PROJECT | Daily skim executed"
  echo "$NOW | SECURITY | Special Projects menu unlocked"
} >> "$LOG_DIR/ops.log"

# ---- ACH sample files
echo "NACHA BATCH (demo) INCOMING — looks legit." > "$ACH_INBOX/ACH_IN_19990315.nacha"
echo "NACHA BATCH (demo) OUTGOING — payroll for Initech." > "$ACH_OUTBOX/ACH_OUT_PAYROLL_19990315.nacha"

# ---- Pending wire (matches app format)
cat > "$WIRE_QUEUE/WIRE.19990315111500.4242" <<'EOF'
DACC=123456789|CNAME=PC LOAD LETTER LLC|CABA=021000021|CACC=0007771337|AMT=42.00|TS=1999-03-15 11:15:00
EOF

# ---- Special Projects config
echo "0.25" > "$PROJECT_DIR/rounding.cfg"

# ---- A couple of placeholder docs
echo "Signature Card - Peter Gibbons (red stapler imprint faintly visible)" > "$DOC_STORE/sigcard_peter.txt"
echo "Fax: Wire Authorization Form (coversheet says 'Yeahhhh')" > "$DOC_STORE/wire_fax_joanna.txt"

echo "Seed complete. Fire up the TUI!"

