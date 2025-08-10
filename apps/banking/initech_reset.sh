#!/usr/local/bin/bash
# Reset /export/banking to baseline seeded state
# Solaris 7 friendly — removes transient data and reseeds with baseline

DATA_ROOT="/export/banking"
SEED_SCRIPT="./initech_seed.sh"

say() { printf "%s\n" "$*"; }
pause() { sleep 1; }

# Safety check
if [ "$DATA_ROOT" = "/" ] || [ -z "$DATA_ROOT" ]; then
  echo "Refusing to run — DATA_ROOT is unsafe: $DATA_ROOT" >&2
  exit 1
fi

if [ ! -d "$DATA_ROOT" ]; then
  echo "Directory $DATA_ROOT does not exist, creating..."
  mkdir -p "$DATA_ROOT"
fi

say "[*] Removing logs, queued payments, docs, and special project data..."
rm -f "$DATA_ROOT"/log/* \
      "$DATA_ROOT"/ach/incoming/* \
      "$DATA_ROOT"/ach/outgoing/* \
      "$DATA_ROOT"/wires/pending/* \
      "$DATA_ROOT"/docs/* \
      "$DATA_ROOT"/special_projects/* \
      2>/dev/null

say "[*] Resetting accounts database..."
rm -f "$DATA_ROOT/state/accounts.db"

say "[*] Running seed script..."
if [ -x "$SEED_SCRIPT" ]; then
  /usr/local/bin/bash "$SEED_SCRIPT"
else
  echo "Seed script not found or not executable: $SEED_SCRIPT" >&2
  exit 2
fi

say "[*] Reset complete."
pause

