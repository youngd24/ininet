# ININET Banking System - Modular Library

This directory contains the modular components of the ININET Banking System, designed for compatibility with both Solaris 7 + bash 4.1.0 + dialog 1.0 and Ubuntu 24 + bash 5.2 + dialog 1.3.

## Module Structure

**Note**: All modules are designed to be sourced from the main script (`initech_bank_mvp_modular.sh`) where `core.sh` is sourced first. The modules do not source each other independently to avoid circular dependencies and path resolution issues.

### Core Infrastructure (`core.sh`)
- **Environment Setup**: Data directories, tool detection, compatibility fallbacks
- **Tool Detection**: Automatic detection of awk, grep, dialog, tail with Solaris XPG4 fallbacks
- **Y2K Date Handling**: Date normalization, validation, and rollover simulation
- **Logging Functions**: Operations log and wire history logging
- **Utility Functions**: Common helpers like `to_upper()`, `compare_money_ge()`

### UI Framework (`ui.sh`)
- **Dialog Wrappers**: Standardized message, input, and confirmation dialogs
- **Security Comedy**: Milton lockdown and Lumbergh lockout easter eggs
- **User Input Handling**: Consistent input validation and error handling

### Wire Transfer Module (`wires.sh`)
- **Wire Operations**: Entry, review, release, amend, cancel
- **OFAC Scanning**: Name-based compliance checking against watch lists
- **File I/O**: Wire data persistence and retrieval
- **Form Generation**: Fedwire-style printable stubs
- **Dual Control**: Maker/checker workflow enforcement

### Customer Management (`customers.sh`)
- **Account Operations**: Open, close, freeze accounts
- **Signer Management**: Add/remove authorized users
- **Customer Lookup**: Search by name, tax ID, or account number
- **Database Operations**: Account record management

### ACH Module (`ach.sh`)
- **Inbox Management**: View incoming ACH files
- **Origination**: Queue NACHA files for transmission
- **Returns Processing**: Log return codes and notes
- **Batch Operations**: Simulated posting and transmission

### Compliance Module (`compliance.sh`)
- **OFAC Checking**: Manual compliance logging
- **CTR Filing**: Currency Transaction Report stubs
- **Audit Logging**: Operations log viewing
- **Risk Management**: Compliance workflow stubs

### Back Office (`backoffice.sh`)
- **End-of-Day Operations**: Posting and reconciliation stubs
- **Document Storage**: Paper/microfilm workflow placeholders
- **Y2K Tools**: Date conversion, scanning, and testing
- **Special Projects**: Peter's secret menu (rounding errors, skim jobs)

### Statements Module (`statements.sh`)
- **Balance Reporting**: End-of-day balance views
- **Monthly Statements**: Paper statement workflow stubs
- **Commercial Exports**: BAI2 and fixed-width file generation

## Usage

### Running the Modular Version
```bash
# From the banking directory
./initech_bank_mvp_modular.sh
```

### Individual Module Testing
```bash
# Test the main modular script
./initech_bank_mvp_modular.sh

# Test individual modules (from the banking directory)
./tests/test_modular.sh

# Or test from the tests directory
cd tests
./test_modular.sh
```

### Adding New Modules
1. Create new module file in `lib/` directory
2. Source core functions: `. "$(dirname "$0")/core.sh"`
3. Implement module-specific functions
4. Add module to main script sourcing
5. Integrate into appropriate menu structure

## Compatibility Features

### Solaris 7 Compatibility
- XPG4 tool fallbacks (`/usr/xpg4/bin/awk`, `/usr/xpg4/bin/grep`)
- POSIX-safe shell constructs (no process substitution, here-strings)
- Compatible with bash 4.1.0 features
- Works with dialog 1.0 limitations

### Ubuntu 24 Compatibility
- Modern tool detection and fallbacks
- Compatible with bash 5.2 features
- Enhanced dialog 1.3 support
- Maintains backward compatibility

### Cross-Platform Features
- Automatic tool detection and fallback
- Consistent error handling
- Portable date handling
- Unified logging interface

## Benefits of Modularization

1. **Maintainability**: Easier to locate and fix specific functionality
2. **Reusability**: Modules can be sourced independently for testing
3. **Testing**: Individual modules can be unit tested
4. **Development**: Multiple developers can work on different modules
5. **Documentation**: Clear separation of concerns
6. **Debugging**: Isolated issues to specific modules
7. **Extensions**: Easy to add new functionality without touching existing code

## Migration from Monolithic Script

The original `initech_bank_mvp.sh` has been refactored into this modular structure. All functionality is preserved, but now organized into logical, maintainable components.

To migrate existing deployments:
1. Deploy the `lib/` directory alongside the main script
2. Replace the main script with `initech_bank_mvp_modular.sh`
3. Test functionality to ensure compatibility
4. Remove the old monolithic script once verified

## File Permissions

Ensure all module files are executable:
```bash
chmod +x lib/*.sh
chmod +x initech_bank_mvp_modular.sh
```
