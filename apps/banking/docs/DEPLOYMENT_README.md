# ININet Banking Deployment Guide

## Overview

This deployment script (`deploy_initech_banking.sh`) automates the deployment of the ININet banking application to the target environment.

## What Gets Deployed

The script copies the following files:

- **All files from `lib/*`** → `/export/initech/banking/lib/`
- **`initech_bank_mvp_modular.sh`** → `/export/initech/banking/` (with 755 permissions)

## OS Compatibility

- **Solaris 7** with bash 4.1.0
- **Ubuntu 24** with bash 5.2 and dialog 1.3

## Prerequisites

1. The script must be run from the root of the ININet project directory
2. Write permissions to `/export/initech/banking/` (or parent directories)
3. Bash shell available

## Usage

### Basic Deployment
```bash
./deploy_initech_banking.sh
```

### Dry Run (Preview)
```bash
./deploy_initech_banking.sh --dry-run
```

### Verbose Output
```bash
./deploy_initech_banking.sh --verbose
```

### Help
```bash
./deploy_initech_banking.sh --help
```

## What the Script Does

1. **OS Detection**: Automatically detects the operating system and validates compatibility
2. **Prerequisites Check**: Verifies source files exist and target permissions
3. **Directory Creation**: Creates `/export/initech/banking/` and `/export/initech/banking/lib/` if they don't exist
4. **File Copying**: Copies all lib files and the main script
5. **Permission Setting**: Sets the main script to 755 (rwxr-xr-x)
6. **Verification**: Confirms all files were copied correctly
7. **Summary**: Displays deployment results

## Target Directory Structure

After deployment, the target will have this structure:

```
/export/initech/banking/
├── initech_bank_mvp_modular.sh (755 permissions)
└── lib/
    ├── ach.sh
    ├── backoffice.sh
    ├── compliance.sh
    ├── core.sh
    ├── customers.sh
    ├── README.md
    ├── statements.sh
    ├── test_standalone.sh
    ├── ui.sh
    ├── wires.sh
    └── y2k.sh
```

## Error Handling

The script includes comprehensive error handling:

- Exits on any error (`set -e`)
- Validates source files exist before copying
- Checks write permissions to target directories
- Verifies file counts match after copying
- Provides detailed error messages and logging

## Logging

The script provides color-coded output for different message types:
- **Blue**: Information messages
- **Green**: Success messages  
- **Yellow**: Warning messages
- **Red**: Error messages

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure you have write access to `/export/initech/banking/`
2. **Source Not Found**: Run the script from the ININet project root directory
3. **OS Not Supported**: The script will warn but attempt to continue

### Debug Mode

Use `--verbose` to see detailed output of each operation.

### Dry Run

Use `--dry-run` to see what would happen without actually copying files.

## Security Notes

- The script creates directories with default permissions
- The main script is set to 755 (executable by owner, readable/executable by group and others)
- Lib files maintain their original permissions

## Support

For issues or questions about the deployment script, refer to the ININet project documentation or contact the development team.
