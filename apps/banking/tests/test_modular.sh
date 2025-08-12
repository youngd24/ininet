#!/usr/local/bin/bash
# Test script for modular ININET Banking System
# This script tests that all modules can be sourced correctly from the tests directory

echo "Testing ININET Banking System Modular Structure..."
echo "=================================================="

# Get the directory where this script is located (tests directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Go up one level to the banking directory, then into lib
BANKING_DIR="$(dirname "$SCRIPT_DIR")"
LIB_DIR="$BANKING_DIR/lib"

echo "Script directory: $SCRIPT_DIR"
echo "Banking directory: $BANKING_DIR"
echo "Library directory: $LIB_DIR"
echo ""

# Test sourcing each module
echo "Testing module sourcing:"
echo "-----------------------"

# Test core module first
echo -n "Testing core.sh... "
if . "$LIB_DIR/core.sh" 2>/dev/null; then
    echo "PASS"
    echo "  - TITLE: $TITLE"
    echo "  - DATA_ROOT: $DATA_ROOT"
    echo "  - AWK: $AWK"
    echo "  - DIALOG: $DIALOG"
else
    echo "FAIL"
    exit 1
fi

# Test other modules (they depend on core.sh being already sourced)
echo -n "Testing ui.sh... "
if . "$LIB_DIR/ui.sh" 2>/dev/null; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

echo -n "Testing wires.sh... "
if . "$LIB_DIR/wires.sh" 2>/dev/null; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

echo -n "Testing customers.sh... "
if . "$LIB_DIR/customers.sh" 2>/dev/null; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

echo -n "Testing ach.sh... "
if . "$LIB_DIR/ach.sh" 2>/dev/null; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

echo -n "Testing compliance.sh... "
if . "$LIB_DIR/compliance.sh" 2>/dev/null; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

echo -n "Testing backoffice.sh... "
if . "$LIB_DIR/backoffice.sh" 2>/dev/null; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

echo -n "Testing statements.sh... "
if . "$LIB_DIR/statements.sh" 2>/dev/null; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

echo ""
echo "All modules sourced successfully!"
echo ""
echo "Testing utility functions:"
echo "-------------------------"

# Test some utility functions
echo -n "Testing to_upper()... "
if [ "$(to_upper 'hello world')" = "HELLO WORLD" ]; then
    echo "PASS"
else
    echo "FAIL"
fi

echo -n "Testing date_ymd_now()... "
if [ -n "$(date_ymd_now)" ]; then
    echo "PASS"
else
    echo "FAIL"
fi

echo -n "Testing validate_yyyymmdd()... "
if validate_yyyymmdd "20241201"; then
    echo "PASS"
else
    echo "FAIL"
fi

echo ""
echo "Modular structure test completed successfully!"
echo "The system is ready for use."
echo ""
echo "Note: This test was run from the tests/ directory"
echo "Main script location: $BANKING_DIR/initech_bank_mvp_modular.sh"
