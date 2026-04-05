#!/bin/bash
###############################################################################
#
# backup.sh 
#
# Collects network device configs, scrubs sensitive data, and commits/pushes
# the results to a git repository.
#
# Copyright (c) 2026 Darren Young. All rights reserved.
#
###############################################################################

SCRIPTDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BASEDIR=$(dirname "$SCRIPTDIR")
CONFIGDIR="$BASEDIR/configs"
LOGFILE="$SCRIPTDIR/backup.log"
DATE=$(date)

echo "SCRIPTDIR: $SCRIPTDIR"
echo "CONFIGDIR: $CONFIGDIR"
echo "LOGFILE:   $LOGFILE"

if [[ ! -d "$CONFIGDIR" ]]; then
    echo "ERROR: CONFIGDIR does not exist: $CONFIGDIR"
    exit 1
fi

for script in "$SCRIPTDIR/getconfigs.exp" "$SCRIPTDIR/clean.sh"; do
    if [[ ! -x "$script" ]]; then
        echo "ERROR: Script not found or not executable: $script"
        exit 1
    fi
done

if [[ -f "$LOGFILE" ]]; then
    echo "Rotating previous logfile"
    mv "$LOGFILE" "$LOGFILE.prev"
fi

echo -n "Gathering configs... "
"$SCRIPTDIR/getconfigs.exp" >> "$LOGFILE" 2>&1
RESULT=$?
if [[ $RESULT -ne 0 ]]; then
    echo "[FAILED]"
    exit 1
else
    echo "[DONE]"
fi

echo -n "Cleaning out sensitive bits... "
"$SCRIPTDIR/clean.sh" >> "$LOGFILE" 2>&1
RESULT=$?
if [[ $RESULT -ne 0 ]]; then
    echo "[FAILED]"
    exit 1
else
    echo "[DONE]"
fi

echo -n "Git commit... "
if git -C "$CONFIGDIR" diff --cached --quiet && git -C "$CONFIGDIR" diff --quiet; then
    echo "[SKIPPED - nothing to commit]"
else
    git -C "$CONFIGDIR" commit -a -m "Backup on $DATE" >> "$LOGFILE" 2>&1
    RESULT=$?
    if [[ $RESULT -ne 0 ]]; then
        echo "[FAILED]"
        exit 1
    else
        echo "[DONE]"
    fi
fi

echo -n "Git push... "
git -C "$CONFIGDIR" push >> "$LOGFILE" 2>&1
RESULT=$?
if [[ $RESULT -ne 0 ]]; then
    echo "[FAILED]"
    exit 1
else
    echo "[DONE]"
fi