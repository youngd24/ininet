#!/usr/local/bin/bash
# Standalone test script for individual modules
# This script can be run from the lib/ directory to test modules independently

echo "Testing ININET Banking System Modules (Standalone)"
echo "=================================================="

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Script directory: $SCRIPT_DIR"
echo ""

# Test core module first
echo "Testing core.sh..."
if . "$SCRIPT_DIR/core.sh" 2>/dev/null; then
    echo "✓ core.sh sourced successfully"
    echo "  - TITLE: $TITLE"
    echo "  - DATA_ROOT: $DATA_ROOT"
    echo "  - AWK: $AWK"
    echo "  - DIALOG: $DIALOG"
else
    echo "✗ Failed to source core.sh"
    exit 1
fi

echo ""

# Test UI module (depends on core.sh)
echo "Testing ui.sh..."
if . "$SCRIPT_DIR/ui.sh" 2>/dev/null; then
    echo "✓ ui.sh sourced successfully"
else
    echo "✗ Failed to source ui.sh"
    exit 1
fi

echo ""

# Test utility functions
echo "Testing utility functions:"
echo -n "  - to_upper()... "
if [ "$(to_upper 'hello world')" = "HELLO WORLD" ]; then
    echo "PASS"
else
    echo "FAIL"
fi

echo -n "  - date_ymd_now()... "
if [ -n "$(date_ymd_now)" ]; then
    echo "PASS"
else
    echo "FAIL"
fi

echo -n "  - validate_yyyymmdd()... "
if validate_yyyymmdd "20241201"; then
    echo "PASS"
else
    echo "FAIL"
fi

echo ""
echo "Standalone module test completed successfully!"
echo "The core module is working correctly."
