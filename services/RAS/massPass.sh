#!/bin/bash
##############################################################################
#
# massPass.sh
#
# Reset all INITECH users passwords back to their demo defaults
#
##############################################################################

PASSFILE="../../auth0/passwd"
CREATE_SCRIPT="./changePwd.sh"
LOGFILE="passbatch.log"

# Flip through the password file, skip comments and blank lines
echo "Loading all users into RAS using API..." | tee $LOGFILE

for line in `cat $PASSFILE | grep -v '#'`; do
    [ -z "$line" ] && continue

    USERNAME=`echo $line | awk -F: '{print $1}'`
    PASSWORD=`echo $line | awk -F: '{print $2}'`

    echo "Creating $USERNAME" | tee -a $LOGFILE
    ./changePwd.sh $USERNAME $PASSWORD | tee -a $LOGFILE

done
