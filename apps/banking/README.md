# INITECH Banking System - Complete Documentation

## INTRODUCTION

Welcome to the INITECH Banking System — the late-90s solution for ACH, Wires, and
a few "Special Projects" that Finance doesn't ask about.

This build is for demonstration purposes only at Vintage Computer Fest.
No real money moves, but a lot of fictional pennies might.

**NEW IN THIS VERSION**: Modular architecture, Milton's Stapler Quest, and enhanced Office Space easter eggs!

## SYSTEM REQUIREMENTS

* Operating System: Solaris 7 (SunOS 5.7) **OR** Ubuntu 24+
* Shell: `/usr/bin/sh` (POSIX compliant) - **UPDATED for cross-platform compatibility**
* UI: dialog 1.0+ (with fallback text menus)
* Disk Space: 5MB (plus 10MB for "document imaging" that's really text files)
* Human Factors:
  * 1 bored sysadmin
  * 1 middle manager who says "Yeahhhh…" a lot
  * 1 Milton who's very protective of his red Swingline stapler

## DIRECTORY STRUCTURE

```
   /export/banking
   ├── ach/                # ACH payment files (incoming/outgoing)
   ├── wires/              # Wire transfer queue
   ├── log/                # Operational and "Special Projects" logs
   ├── docs/               # Scanned forms & signature cards
   ├── state/              # Flat-file databases (SQL licenses cost money)
   └── special_projects/   # Rounding configs, skim history, & stapler quest state
```

## MODULAR ARCHITECTURE - WHAT'S UNDERNEATH

### Main Scripts
* **`initech_bank_mvp_modular.sh`** - **NEW**: Main entry point with modular design
* **`initech_bank_mvp.sh`** - Original monolithic version (kept for reference)
* **`initech_bank_mvp-0.2.sh`** - Backup version in `/backup/` directory

### Library Modules (`/lib/`)
* **`core.sh`** - Core infrastructure, environment setup, and Y2K utilities
* **`ui.sh`** - UI framework, dialog wrappers, and Office Space themed error messages
* **`customers.sh`** - Customer management, account operations, and signer management
* **`ach.sh`** - ACH processing, batch operations, and file management
* **`wires.sh`** - Wire transfer system, dual control, and OFAC screening
* **`compliance.sh`** - Risk management, OFAC checks, and CTR reporting
* **`backoffice.sh`** - End-of-day operations and Peter's Special Projects
* **`statements.sh`** - Account statements, exports, and document generation
* **`y2k.sh`** - Y2K compliance tools and date conversion utilities

### Control & Demo Scripts
* **`/control/`** - System management and seeding tools
  * `initech_seed.sh` - Baseline data seeding
  * `initech_reset.sh` - System reset and cleanup
  * `vcf_control.sh` - VCF demonstration control panel
  * `wire_cli.sh` - Wire transfer command-line interface
* **`/demo/`** - Demonstration and tour scripts
  * `initech_demo_tour.sh` - Pre-loaded jokes and suspicious activities
* **`/tests/`** - Testing and validation scripts
  * `test_modular.sh` - Modular system testing
  * `ubuntu_tui_smoke.sh` - Ubuntu compatibility testing

## OPERATING INSTRUCTIONS

### Quick Start
1. **Run the main application**: `./initech_bank_mvp_modular.sh`
2. **Access Special Projects**: Enter "TPS" as access code
3. **Try the Easter Egg**: Enter "Milton" as access code for the stapler quest

### VCF Control Panel
Run the VCF Control Panel for demonstrations:

```bash
./control/vcf_control.sh
```

Options include:
* **Reset to Baseline** – wipe all traces of shenanigans, reseed cast & data
* **Seed Baseline** – add default customers (Peter, Samir, Milton, etc.)
* **Run Demo Tour** – pre-load jokes, suspicious logs, and a fake wire
* **Launch INITECH TUI** – main menu for banking ops
* **View Audit Log** – see what Compliance will yell about

## SPECIAL ACCESS CODES - ENHANCED

* **"TPS"** → Unlocks Special Projects menu for rounding-error skims
* **"Milton"** → 🎯 **NEW**: Direct access to Milton's Stapler Quest!
* **"911"** (wire amount) → Milton panic mode: locks down the terminal

## NEW FEATURES - WHAT'S CHANGED

### 1. Milton's Red Swingline Stapler Quest
**Access**: Enter "Milton" as access code at startup
**What it does**: Interactive quest to find Milton's missing stapler
**Locations to search**:
- ACH Processing Department
- Wire Transfer Office  
- Compliance & Risk
- Customer Service
- Back Office Operations
- **The Basement** (where it's actually hidden!)
- Lumbergh's Office

**Rewards**: 
- Office Space Mode unlocked
- Random themed error messages throughout the system
- Milton stops threatening to burn the building down

### 2. Office Space Mode
**Triggered by**: Completing the stapler quest
**Features**:
- Paper jam errors mention the red Swingline stapler
- TPS report errors with classic Office Space dialogue
- Milton quotes in compliance messages
- 1 in 20 chance for themed errors after quest completion

### 3. Enhanced Special Projects Menu
**New option**: "Reset Stapler Quest State" - clears quest completion for replay
**Purpose**: Allow multiple VCF attendees to experience the easter egg
**Safety**: Confirmation dialog prevents accidental resets

### 4. Modular Architecture Benefits
- **Maintainability**: Each function in its own module
- **Testing**: Individual modules can be tested separately
- **Extensibility**: Easy to add new features
- **Cross-Platform**: Better compatibility between Solaris and Ubuntu

## COMPLIANCE NOTES

* OFAC checks are manual. Keep a paper list.
* CTR filing done with actual pens.
* Any resemblance to real banks is purely coincidental… except the funny parts.
* **NEW**: Milton's stapler quest state is logged for audit purposes

## EASTER EGGS & KNOWN "FEATURES"

### Classic Easter Eggs
* PC LOAD LETTER LLC – escrow account & frequent payee
* TPS Consulting LLC – recipient of fractions-of-a-cent skims
* Signature cards feature faint red stapler imprints
* Wire fax coversheets say "Yeahhhh" in Comic Sans

### NEW Easter Eggs
* **Milton's Stapler Quest**: Complete interactive adventure
* **Office Space Mode**: Themed error messages and dialogue
* **Quest State Management**: Persistent progress tracking
* **Enhanced Logging**: Easter egg activities logged with special categories

## TECHNICAL IMPROVEMENTS

### Cross-Platform Compatibility
- **Shell**: Now uses `/usr/bin/sh` instead of bash-specific features
- **Utilities**: Fallback mechanisms for Solaris vs Ubuntu differences
- **Testing**: Dedicated test scripts for each platform

### State Management
- **Quest Progress**: Stored in `/export/banking/special_projects/stapler_found.flag`
- **Logging**: Enhanced logging with `EASTER_EGG` category
- **Persistence**: Quest completion persists across sessions

### Error Handling
- **Office Space Integration**: Context-aware error messages
- **Fallback Mechanisms**: Graceful degradation when features unavailable
- **User Feedback**: Clear messages about what's happening

## VCF MIDWEST DEMONSTRATION GUIDE

### For Attendees
1. **Try the Access Codes**: Start with "Milton" for immediate fun
2. **Explore the Quest**: Don't give up after a few wrong locations
3. **Look for References**: TPS reports, basement, and Milton's dialogue
4. **Check Error Messages**: After completing quest, watch for themed errors

### For Presenters
1. **Reset Between Sessions**: Use "Reset Stapler Quest State" option
2. **Multiple Demonstrations**: Quest can be completed multiple times
3. **Cross-Platform Showcase**: Works on both Solaris and Ubuntu
4. **Interactive Experience**: Let attendees discover the easter eggs

## DEVELOPMENT NOTES

### Adding New Features
- **New Modules**: Add to `/lib/` directory and source in main script
- **Easter Eggs**: Integrate with existing Office Space theme
- **Cross-Platform**: Test on both Solaris 7 and Ubuntu 24

### Testing
- **Modular Testing**: `./tests/test_modular.sh`
- **Platform Testing**: `./tests/ubuntu_tui_smoke.sh`
- **Smoke Tests**: Various test scripts in `/tests/` directory

---

**©1999 INITECH Corp. – Bringing You & Us Together™**  
*Printed in the USA on recycled TPS reports.*

*"I believe you have my stapler..." - Milton Waddams*
*"Yeah... if you could go ahead and find it, that'd be great. M'kay?" - Lumbergh*
