# INITECH Applications Directory

## Overview
This directory contains the core applications that make up the INITECH (Innovation + Technology) system - a vintage computing platform designed to recreate the late 1990s banking and office environment from the movie "Office Space."

## Directory Structure

### `/banking/` - Initech Banking System
**What it does:** A fully functional banking management system built with bash scripting and dialog-based UI, designed to look and feel like a late 1990s banking application.

**What's underneath:**
- **Core Banking Functions**: Customer management, account operations, ACH processing, wire transfers
- **Y2K Compliance Tools**: Date conversion utilities, rollover testing, millennium bug simulation
- **Office Space Easter Eggs**: Hidden quests, themed error messages, and pop culture references
- **Modular Architecture**: Split into logical modules (core.sh, ui.sh, wires.sh, customers.sh, etc.)
- **Cross-Platform**: Works on both Solaris 7 and Ubuntu 24 with fallback compatibility

**Key Features:**
- Customer & Account Management (open/close/freeze accounts, manage signers)
- Payment Processing (ACH batch operations, wire transfers with dual control)
- Compliance & Risk Management (OFAC screening, CTR reporting, fraud detection)
- Back Office Operations (end-of-day processing, document management)
- Special Projects (Peter's secret tools for "rounding errors")
- Milton's Stapler Quest (hidden easter egg accessible via "Milton" access code)

### `/finance/` - Finance System
**What it does:** A financial management and reporting system, likely handling accounting, reporting, and financial data processing.

**What's underneath:**
- **VAPID**: Main finance application (details in vapid subdirectory)
- **Upload Tools**: File upload and processing utilities
- **Financial Reports**: Data export and reporting capabilities

### `/launcher` - Application Launcher
**What it does:** A centralized menu system that allows users to select and launch different INITECH applications from a single interface.

**What's underneath:**
- **Dialog-Based UI**: Uses the `dialog` utility for terminal-based graphical menus
- **Cross-Platform Shell**: Written in portable `/usr/bin/sh` for Solaris 7 and Ubuntu 24 compatibility
- **Application Management**: Handles launching, monitoring, and returning from applications
- **Retro Styling**: Vintage computing aesthetic with ASCII banners and classic terminal UI

**Available Applications:**
1. **Bank Management System** - Launches the modular banking application
2. **Finance System** - Launches the VAPID finance application  
3. **Check Email** - Launches Pine email client
4. **System Shell** - Provides direct access to system shell (`/usr/bin/sh`)

## Technical Architecture

### Shell Scripting Foundation
- **Primary Language**: Bash/Shell scripting for maximum vintage computing authenticity
- **UI Framework**: Dialog utility for terminal-based graphical interfaces
- **Error Handling**: Comprehensive logging and user feedback systems
- **Cross-Platform**: Solaris 7 and Ubuntu 24 compatibility with fallback mechanisms

### Modular Design
- **Separation of Concerns**: Each major function split into logical modules
- **Library System**: Common functions shared across applications via lib/ directories
- **Configuration Management**: Environment-specific settings and fallbacks
- **State Persistence**: File-based state management for user progress and settings

### Vintage Computing Features
- **Y2K Simulation**: Millennium bug testing and date rollover simulation
- **Classic UI**: Terminal-based interfaces reminiscent of 1990s banking systems
- **Retro Styling**: ASCII art banners, classic color schemes, vintage terminology
- **Office Space Integration**: Pop culture references and hidden easter eggs

## Access Codes & Easter Eggs

### Banking System Access
- **"TPS"** - Unlocks Special Projects menu (Peter's playground)
- **"Milton"** - 🎯 **DIRECT ACCESS** to Milton's Stapler Quest
- **"911"** - Triggers Milton Incident lockdown (forbidden wire amount)

### Hidden Features
- **Stapler Quest**: Interactive search for Milton's missing red Swingline stapler
- **Office Space Mode**: Themed error messages after completing the quest
- **Special Projects**: Peter's secret tools for financial "optimization"
- **Y2K Tools**: Millennium bug testing and date conversion utilities

## VCF Midwest Appeal

This system is designed specifically for vintage computing festivals like VCF Midwest, offering:

- **Authentic Experience**: Real late 1990s computing environment
- **Interactive Content**: Hidden easter eggs and quests to discover
- **Educational Value**: Demonstrates Y2K issues and vintage banking systems
- **Pop Culture**: Office Space references that resonate with tech professionals
- **Cross-Platform**: Works on both Solaris and Linux vintage systems
- **Modular Design**: Easy to extend and customize for demonstrations

## Getting Started

1. **Launch the System**: Run `./launcher` from the apps directory
2. **Access Banking**: Select "Bank Management System" from the menu
3. **Try Easter Eggs**: Enter "Milton" as access code for the stapler quest
4. **Explore Features**: Navigate through different banking functions
5. **Discover Secrets**: Look for hidden Office Space references throughout

## System Requirements

- **Operating System**: Solaris 7+ or Ubuntu 24+
- **Shell**: `/usr/bin/sh` (POSIX compliant)
- **Utilities**: `dialog`, `awk`, `grep`, `tail`
- **Permissions**: Read/execute access to application directories
- **Terminal**: VT100-compatible terminal or terminal emulator

---

*"Innovation + Technology" - INITECH Corporation*
*"I believe you have my stapler..." - Milton Waddams*
