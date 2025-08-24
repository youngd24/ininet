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

# Remove existing log at startup (start clean)
[ -f "$LOGFILE" ] && rm -f "$LOGFILE"

# Logger: print to stdout and append to log
logmsg() {
    printf '%s\n' "$*" | tee -a "$LOGFILE" >/dev/null
}

# Flip through the password file, skip comments and blank lines
echo "Mass changing passwords back to demo defaults"

for line in `cat $PASSFILE | grep -v '#'`; do
    [ -z "$line" ] && continue

    USERNAME=`echo $line | awk -F: '{print $1}'`
    PASSWORD=`echo $line | awk -F: '{print $2}'`

    logmsg "Changing password for $USERNAME"
    output=$("$CREATE_SCRIPT" "$USERNAME" "$PASSWORD")
    logmsg "$output"
done

