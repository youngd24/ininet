#!/bin/bash
#

DATE=$(date)
WORKDIR=$(pwd)
BASEDIR=$(dirname "$WORKDIR")
CONFIGDIR="$BASEDIR/configs"
LOGFILE="$WORKDIR/backup.log"

echo "WORKDIR: $WORKDIR"
echo "CONFIGDIR: $CONFIGDIR"
echo "LOGFILE: $LOGFILE"

if [[ -f "$LOGFILE" ]]; then
    echo "Clearing previous logfile"
    rm -f "$LOGFILE"
fi

echo -n "Gathering configs... "
"$WORKDIR/getconfigs.exp" >> "$LOGFILE" 2>&1
RESULT=$?
if [[ $RESULT -ne 0 ]]; then
    echo "[FAILED]"
    exit 1
else
    echo "[DONE]"
fi

echo -n "Cleaning out sensitive bits... "
"$WORKDIR/clean.sh" >> "$LOGFILE" 2>&1
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