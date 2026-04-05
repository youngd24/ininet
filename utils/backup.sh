#!/bin/bash
#

WORKDIR=$(pwd)
BASEDIR=$(dirname "$WORKDIR")
CONFIGDIR="$BASEDIR/configs"
LOGFILE="$WORKDIR/backup.log"

echo "WORKDIR: $WORKDIR"
echo "CONFIGDIR: $CONFIGDIR"
echo "LOGFILE: $LOGFILE"

echo "Gathering configs"
$WORKDIR/getconfigs.exp
RESULT=$?
if [[ $RESULT -ne 0 ]]; then
    echo "FAILED TO GET CONFIGS"
    exit 1
else
    echo "SUCCESSFULLY GATHERED CONFIGS"
fi

echo "Cleaning out sensitive and unneeded aspects"
$WORKDIR/clean.sh
RESULT=$?
if [[ $RESULT -ne 0 ]]; then
    echo "FAILED TO CLEAN CONFIGS"
    exit 1
else
    echo "SUCCESSFULLY CLEANED CONFIGS"
fi
