#!/bin/sh
# ubuntu_tui_smoke.sh — helper to run the Expect-driven TUI smoke test on Ubuntu.
# Installs dependencies (dialog, expect) if missing, initializes data dirs, then runs expect.
set -e

# Ensure we run from the package directory
cd "$(dirname "$0")"

if ! command -v dialog >/dev/null 2>&1; then
  echo "Installing dialog..."
  sudo apt-get update -y && sudo apt-get install -y dialog
fi

if ! command -v expect >/dev/null 2>&1; then
  echo "Installing expect..."
  sudo apt-get update -y && sudo apt-get install -y expect
fi

# Initialize directories and clear prior state for a clean run
export DATA_ROOT=/export/banking
mkdir -p "$DATA_ROOT"
# Use the CLI harness to init
chmod +x wire_cli.sh initech_bank_mvp.sh tui_smoketest.expect
./wire_cli.sh init

# Remove any previous pending wire so ID is predictable
rm -f /export/banking/wires/pending/WIRE.* 2>/dev/null || true

echo "Launching TUI smoke test..."
expect ./tui_smoketest.expect

echo "Smoke test complete. Check:"
echo "  - /export/banking/wires/released for a .released file"
echo "  - /export/banking/wires/forms for a corresponding .txt form"
echo "  - /export/banking/wires/wires.log for history entries"
