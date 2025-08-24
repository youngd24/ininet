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

# Flip through the password file, skip comments and blank lines
echo "Loading all users into RAS using API..." | tee $LOGFILE

# do work
for line in `cat $PASSFILE | grep -v '#'`; do
    [ -z "$line" ] && continue

    USERNAME=`echo $line | awk -F: '{print $1}'`
    PASSWORD=`echo $line | awk -F: '{print $2}'`

    echo "Creating $USERNAME" | tee -a $LOGFILE
    ./createUser.sh $USERNAME $PASSWORD | tee -a $LOGFILE

done
