#!/bin/bash
##############################################################################
#
# createUser.sh
#
# Create a RAS (AIM) user via the API
#
##############################################################################

# Gotta give us sumpin to go on
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <screen_name>"
    exit 1
fi

SCREEN_NAME="$1"

# Debugging: show what is being sent
echo "Using screen name: '$SCREEN_NAME'"

# First API call
curl -s -X DELETE -H "Content-Type: application/json" \
     -d "{\"screen_name\":\"$SCREEN_NAME\"}" \
     http://localhost:8080/user

