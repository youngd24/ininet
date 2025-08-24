#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <screen_name> <password>"
    exit 1
fi

SCREEN_NAME="$1"
PASSWORD="$2"

# Debugging: show what is being sent
echo "Using screen name: '$SCREEN_NAME'"
echo "Using password:    '$PASSWORD'"

# Second API call
curl -s -X PUT -H "Content-Type: application/json" \
     -d "{\"screen_name\":\"$SCREEN_NAME\", \"password\":\"$PASSWORD\"}" \
     http://localhost:8080/user/password

echo

