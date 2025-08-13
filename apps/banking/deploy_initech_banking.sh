#!/usr/local/bin/bash
#
# ININet Banking Deployment Script
# Compatible with Solaris 7 (bash 4.1.0) and Ubuntu 24 (bash 5.2)
#
# This script deploys the ININet banking application to /export/initech/banking/
# Usage: ./deploy_initech_banking.sh [--dry-run] [--verbose]
#

set -e  # Exit on any error

# Script configuration
SCRIPT_NAME="deploy_initech_banking.sh"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BANKING_DIR="${SOURCE_DIR}"
TARGET_BASE="/export/initech/banking"
TARGET_LIB="${TARGET_BASE}/lib"
TARGET_SCRIPT="${TARGET_BASE}/initech_bank_mvp_modular.sh"

# Flags
DRY_RUN=false
VERBOSE=false


# Colors for output (Solaris compatible)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

# OS detection function
detect_os() {
    if [ -f /etc/os-release ]; then
        # Modern Linux systems
        . /etc/os-release
        OS_NAME="$NAME"
        OS_VERSION="$VERSION_ID"
    elif [ -f /etc/redhat-release ]; then
        # RHEL/CentOS
        OS_NAME="Red Hat Enterprise Linux"
        OS_VERSION=$(cat /etc/redhat-release | sed 's/.*release \([0-9.]*\).*/\1/')
    elif [ -f /etc/SuSE-release ]; then
        # SUSE
        OS_NAME="SUSE Linux"
        OS_VERSION=$(cat /etc/SuSE-release | head -1 | sed 's/.*release \([0-9.]*\).*/\1/')
    elif [ -f /etc/solaris-release ]; then
        # Solaris
        OS_NAME="Solaris"
        OS_VERSION=$(cat /etc/solaris-release | head -1 | sed 's/.*release \([0-9.]*\).*/\1/')
    elif [ -f /etc/release ]; then
        # Solaris alternative
        if grep -q "Solaris" /etc/release 2>/dev/null; then
            OS_NAME="Solaris"
            OS_VERSION=$(cat /etc/release | head -1 | sed 's/.*release \([0-9.]*\).*/\1/')
        fi
    else
        # Fallback
        OS_NAME="Unknown"
        OS_VERSION="Unknown"
    fi
    
    # Detect bash version
    BASH_VERSION=$(bash --version | head -1 | sed 's/.*version \([0-9.]*\).*/\1/')
    
    log_info "Detected OS: $OS_NAME $OS_VERSION"
    log_info "Bash version: $BASH_VERSION"
    
    # Validate OS compatibility
    case "$OS_NAME" in
        *"Solaris"*)
            if [ "$OS_VERSION" != "7" ]; then
                log_warning "This script is designed for Solaris 7, but detected version $OS_VERSION"
            fi
            ;;
        *"Ubuntu"*)
            if [ "$OS_VERSION" != "24" ]; then
                log_warning "This script is designed for Ubuntu 24, but detected version $OS_VERSION"
            fi
            ;;
        *)
            log_warning "OS $OS_NAME is not officially supported, but attempting to continue"
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if source files exist
    if [ ! -d "$BANKING_DIR" ]; then
        log_error "Source banking directory not found: $BANKING_DIR"
        exit 1
    fi
    
    if [ ! -d "$BANKING_DIR/lib" ]; then
        log_error "Source lib directory not found: $BANKING_DIR/lib"
        exit 1
    fi
    
    if [ ! -f "$BANKING_DIR/initech_bank_mvp_modular.sh" ]; then
        log_error "Source script not found: $BANKING_DIR/initech_bank_mvp_modular.sh"
        exit 1
    fi
    
    # Check if we have write permissions to target
    if [ -d "$TARGET_BASE" ] && [ ! -w "$TARGET_BASE" ]; then
        log_error "No write permission to target directory: $TARGET_BASE"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create target directories
create_target_dirs() {
    log_info "Creating target directories..."
    
    if [ "$DRY_RUN" = true ]; then
        log_verbose "DRY RUN: Would create directory: $TARGET_BASE"
        log_verbose "DRY RUN: Would create directory: $TARGET_LIB"
        return
    fi
    
    # Create base directory
    if [ ! -d "$TARGET_BASE" ]; then
        mkdir -p "$TARGET_BASE"
        log_verbose "Created directory: $TARGET_BASE"
    fi
    
    # Create lib directory
    if [ ! -d "$TARGET_LIB" ]; then
        mkdir -p "$TARGET_LIB"
        log_verbose "Created directory: $TARGET_LIB"
    fi
    
    log_success "Target directories created/verified"
}

# Copy lib files
copy_lib_files() {
    log_info "Copying lib files..."
    
    local source_lib="$BANKING_DIR/lib"
    local copied_count=0
    local error_count=0
    
    for file in "$source_lib"/*; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            
            if [ "$DRY_RUN" = true ]; then
                log_verbose "DRY RUN: Would copy: $file -> $TARGET_LIB/$filename"
                copied_count=$((copied_count + 1))
            else
                if cp "$file" "$TARGET_LIB/$filename" 2>/dev/null; then
                    log_verbose "Copied: $filename"
                    copied_count=$((copied_count + 1))
                else
                    log_error "Failed to copy: $filename"
                    error_count=$((error_count + 1))
                fi
            fi
        fi
    done
    
    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN: Would copy $copied_count lib files"
    elif [ $error_count -eq 0 ]; then
        log_success "Successfully copied $copied_count lib files"
    else
        log_error "Failed to copy $error_count lib files"
        exit 1
    fi
}

# Copy main script
copy_main_script() {
    log_info "Copying main script..."
    
    local source_script="$BANKING_DIR/initech_bank_mvp_modular.sh"
    local filename=$(basename "$source_script")
    
    if [ "$DRY_RUN" = true ]; then
        log_verbose "DRY RUN: Would copy: $source_script -> $TARGET_SCRIPT"
        log_verbose "DRY RUN: Would set permissions 755 on: $TARGET_SCRIPT"
        return
    fi
    
    if cp "$source_script" "$TARGET_SCRIPT"; then
        log_verbose "Copied: $filename"
        
        # Set permissions to 755
        if chmod 755 "$TARGET_SCRIPT"; then
            log_verbose "Set permissions 755 on: $TARGET_SCRIPT"
            log_success "Successfully copied and set permissions on main script"
        else
            log_error "Failed to set permissions on: $TARGET_SCRIPT"
            exit 1
        fi
    else
        log_error "Failed to copy main script"
        exit 1
    fi
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    if [ "$DRY_RUN" = true ]; then
        log_verbose "DRY RUN: Skipping verification"
        return
    fi
    
    local verification_passed=true
    
    # Check if target directories exist
    if [ ! -d "$TARGET_BASE" ]; then
        log_error "Target base directory not found: $TARGET_BASE"
        verification_passed=false
    fi
    
    if [ ! -d "$TARGET_LIB" ]; then
        log_error "Target lib directory not found: $TARGET_LIB"
        verification_passed=false
    fi
    
    # Check if main script exists and has correct permissions
    if [ ! -f "$TARGET_SCRIPT" ]; then
        log_error "Main script not found: $TARGET_SCRIPT"
        verification_passed=false
    else
        local permissions=$(ls -l "$TARGET_SCRIPT" | awk '{print $1}')
        if [ "$permissions" != "-rwxr-xr-x" ]; then
            log_warning "Main script permissions are $permissions, expected -rwxr-xr-x"
        fi
    fi
    
    # Count lib files
    local lib_file_count=$(find "$TARGET_LIB" -type f | wc -l)
    local source_lib_count=$(find "$BANKING_DIR/lib" -type f | wc -l)
    
    if [ $lib_file_count -eq $source_lib_count ]; then
        log_verbose "Lib file count matches: $lib_file_count files"
    else
        log_warning "Lib file count mismatch: expected $source_lib_count, found $lib_file_count"
        verification_passed=false
    fi
    
    if [ "$verification_passed" = true ]; then
        log_success "Deployment verification passed"
    else
        log_error "Deployment verification failed"
        exit 1
    fi
}

# Display summary
display_summary() {
    log_info "=== Deployment Summary ==="
    log_info "Source directory: $BANKING_DIR"
    log_info "Target directory: $TARGET_BASE"
    log_info "Lib files copied to: $TARGET_LIB"
    log_info "Main script copied to: $TARGET_SCRIPT"
    
    if [ "$DRY_RUN" = true ]; then
        log_warning "DRY RUN MODE - No files were actually copied"
    else
        log_success "Deployment completed successfully!"
    fi
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                log_info "Dry run mode enabled"
                shift
                ;;
            --verbose)
                VERBOSE=true
                log_info "Verbose mode enabled"
                shift
                ;;
            --help|-h)
                echo "Usage: $SCRIPT_NAME [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --dry-run    Show what would be done without actually doing it"
                echo "  --verbose    Show detailed output"
                echo "  --help, -h   Show this help message"
                echo ""
                echo "This script deploys the ININet banking application to /export/initech/banking/"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    log_info "Starting ININet Banking deployment..."
    log_info "Script version: 1.0"
    log_info "Source: $SOURCE_DIR"
    
    parse_arguments "$@"
    detect_os
    check_prerequisites
    create_target_dirs
    copy_lib_files
    copy_main_script
    verify_deployment
    display_summary
    
    log_info "Deployment script completed"
}

# Run main function with all arguments
main "$@"
