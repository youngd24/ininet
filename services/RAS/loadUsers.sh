#!/bin/bash
##############################################################################
#
# loadUsers.sh
#
# Bulk load all INITECH users into RAS (AIM) via the scripted API calls
#
##############################################################################

PASSFILE="../../auth0/passwd"
CREATE_SCRIPT="./createUser.sh"
LOGFILE="batch.log"

# Remove existing log at startup (start clean)
[ -f "$LOGFILE" ] && rm -f "$LOGFILE"

# Logger: print to stdout and append to log
logmsg() {
    printf '%s\n' "$*" | tee -a "$LOGFILE" >/dev/null
}

# Flip through the password file, skip comments and blank lines
logmsg "Loading all users into RAS using API..."

# do work
for line in `cat $PASSFILE | grep -v '#'`; do
    [ -z "$line" ] && continue

    USERNAME=`echo $line | awk -F: '{print $1}'`
    PASSWORD=`echo $line | awk -F: '{print $2}'`

    logmsg "Creating $USERNAME"
    "$CREATE_SCRIPT" "$USERNAME" "$PASSWORD" | tee -a "$LOGFILE"
done

