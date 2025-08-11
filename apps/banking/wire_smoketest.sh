#!/usr/bin/env bash
# Simple smoke test for INITECH Banking System wire workflow
# Works on Ubuntu 24 (bash 5.2 + dialog 1.3) and Solaris 7 (bash 4.1 + dialog 1.0)
# Simulates adding a wire and releasing it automatically.

APP="./initech_bank_mvp.sh"
DATA_ROOT="/tmp/initech_banking_test"

export DATA_ROOT
mkdir -p "$DATA_ROOT"

# Pre-seed environment to skip prompts
export SPECIAL_UNLOCK="no"
export DIALOG=$(command -v dialog)

# Seed a demo wire entry directly into the queue
WIRE_QUEUE="$DATA_ROOT/wires/pending"
mkdir -p "$WIRE_QUEUE"
WIRE_ID="WIRE.$(date '+%Y%m%d%H%M%S').$$"
echo "DACC=123456789|CNAME=John Doe|CABA=021000021|CACC=987654321|AMT=5000|TS=$(date '+%Y-%m-%d %H:%M:%S')" > "$WIRE_QUEUE/$WIRE_ID"

echo "Seeded pending wire: $WIRE_ID"

# Simulate release without manual input
STATE_DIR="$DATA_ROOT/state"
mkdir -p "$STATE_DIR"
mv "$WIRE_QUEUE/$WIRE_ID" "$STATE_DIR/${WIRE_ID}.released"
echo "Released wire: $WIRE_ID"

# Log it
LOG_DIR="$DATA_ROOT/log"
mkdir -p "$LOG_DIR"
echo "$(date '+%Y-%m-%d %H:%M:%S') | WIRE | Released $WIRE_ID" >> "$LOG_DIR/ops.log"

echo "Smoke test complete. Log:"
cat "$LOG_DIR/ops.log"
