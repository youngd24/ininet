#!/bin/sh
# wire_cli.sh — non-interactive test harness for the INITECH Banking wire flow.
# Works with Solaris 7 / /bin/sh and modern Linux /bin/sh.
# Uses the same directory structure and file format as the TUI app.
#
# Usage examples:
#   ./wire_cli.sh init
#   ./wire_cli.sh add "100111222" "John Garcia" "026009593" "123456789" "2500.00" DOMESTIC "Invoice 42" 1999-07-16 maker1
#   ./wire_cli.sh list
#   ./wire_cli.sh amend WIRE.19990716101010.12345 AMT 15000.00
#   ./wire_cli.sh release WIRE.1999... approver1
#   ./wire_cli.sh cancel  WIRE.1999... "Client requested cancel"
#   ./wire_cli.sh print   WIRE.1999...
#   ./wire_cli.sh history
#
DATA_ROOT=${DATA_ROOT:-/export/banking}
WIRE_QUEUE="$DATA_ROOT/wires/pending"
WIRE_RELEASED="$DATA_ROOT/wires/released"
WIRE_CANCELED="$DATA_ROOT/wires/canceled"
WIRE_FORMS="$DATA_ROOT/wires/forms"
STATE_DIR="$DATA_ROOT/state"
WIRE_HISTORY="$DATA_ROOT/wires/wires.log"
OFAC_LIST="$STATE_DIR/ofac_list.txt"
HIGH_VALUE_THRESHOLD=${HIGH_VALUE_THRESHOLD:-10000.00}

AWK=${AWK:-/usr/xpg4/bin/awk}
[ -x "$AWK" ] || AWK=${AWK:-/usr/bin/awk}
GREP=${GREP:-/usr/xpg4/bin/grep}
[ -x "$GREP" ] || GREP=${GREP:-/usr/bin/grep}

init_dirs() {
  for d in "$DATA_ROOT" "$WIRE_QUEUE" "$WIRE_RELEASED" "$WIRE_CANCELED" "$WIRE_FORMS" "$STATE_DIR"; do
    [ -d "$d" ] || mkdir -p "$d" || { echo "Cannot create $d" >&2; exit 1; }
  done
  [ -f "$WIRE_HISTORY" ] || : > "$WIRE_HISTORY"
  if [ ! -f "$OFAC_LIST" ]; then
    cat > "$OFAC_LIST" <<EOF
GARCIA
IVANOV
PC LOAD LETTER LLC
EOF
  fi
}

gen_id() {
  # portable timestamp + pid
  TS=$(date '+%Y%m%d%H%M%S')
  echo "WIRE.$TS.$$"
}

save() {
  # $1=file rest via env vars
  printf "DACC=%s|CNAME=%s|CABA=%s|CACC=%s|AMT=%s|TYPE=%s|MEMO=%s|REQDATE=%s|MAKER=%s|OFAC=%s|STATUS=%s|TS=%s\n" \
    "$DACC" "$CNAME" "$CABA" "$CACC" "$AMT" "$TYPE" "$MEMO" "$REQDATE" "$MAKER" "$OFAC" "$STATUS" "$TS" > "$1"
}

load() {
  CONTENT=$(cat "$1")
  OIFS="$IFS"; IFS='|'
  for kv in $CONTENT; do
    k=$(echo "$kv" | sed 's/=.*//')
    v=$(echo "$kv" | sed 's/^[^=]*=//')
    eval "$k=\$v"
  done
  IFS="$OIFS"
}

ofac_scan() {
  name="$1"
  [ -s "$OFAC_LIST" ] || return 0
  upper_name=$(echo "$name" | $AWK '{print toupper($0)}')
  while IFS= read -r pat; do
    [ -z "$pat" ] && continue
    case "$pat" in \#*) continue;; esac
    up=$(echo "$pat" | $AWK '{print toupper($0)}')
    echo "$upper_name" | $GREP -F -i "$up" >/dev/null 2>&1 && return 1
  done < "$OFAC_LIST"
  return 0
}

history() {
  tail -n 50 "$WIRE_HISTORY" 2>/dev/null || true
}

case "$1" in
  init)
    init_dirs
    echo "Initialized under $DATA_ROOT"
    ;;

  add)
    # args: DACC CNAME CABA CACC AMT TYPE MEMO REQDATE MAKER
    init_dirs
    DACC="$2"; CNAME="$3"; CABA="$4"; CACC="$5"; AMT="$6"; TYPE="$7"; MEMO="$8"; REQDATE="$9"; MAKER="${10}"
    [ -n "$REQDATE" ] || REQDATE=$(date '+%Y-%m-%d')
    TS=$(date '+%Y-%m-%d %H:%M:%S')
    OFAC="PASS"; ofac_scan "$CNAME" || OFAC="REVIEW"
    STATUS="PENDING"
    ID=$(gen_id)
    FILE="$WIRE_QUEUE/$ID"
    save "$FILE"
    echo "$(date '+%F %T') | $ID | ENTERED | maker=$MAKER; ofac=$OFAC; amt=$AMT; type=$TYPE" >> "$WIRE_HISTORY"
    echo "$ID"
    ;;

  list)
    init_dirs
    (cd "$WIRE_QUEUE" 2>/dev/null && ls -1 WIRE.* 2>/dev/null) || true
    ;;

  amend)
    # amend ID FIELD VALUE
    init_dirs
    ID="$2"; FIELD="$3"; VALUE="$4"
    FILE="$WIRE_QUEUE/$ID"
    [ -f "$FILE" ] || { echo "Not found: $ID" >&2; exit 1; }
    load "$FILE"
    case "$FIELD" in
      CNAME) CNAME="$VALUE" ;;
      CABA)  CABA="$VALUE"  ;;
      CACC)  CACC="$VALUE"  ;;
      AMT)   AMT="$VALUE"   ;;
      TYPE)  TYPE="$VALUE"  ;;
      MEMO)  MEMO="$VALUE"  ;;
      REQDATE) REQDATE="$VALUE" ;;
      *) echo "Unsupported field"; exit 1;;
    esac
    TS=$(date '+%Y-%m-%d %H:%M:%S')
    OFAC="PASS"; ofac_scan "$CNAME" || OFAC="REVIEW"
    STATUS="PENDING"
    save "$FILE"
    echo "$(date '+%F %T') | $ID | AMENDED | ofac=$OFAC; amt=$AMT; type=$TYPE" >> "$WIRE_HISTORY"
    echo "Amended $ID"
    ;;

  cancel)
    # cancel ID REASON
    init_dirs
    ID="$2"; REASON="$3"
    FILE="$WIRE_QUEUE/$ID"
    [ -f "$FILE" ] || { echo "Not found: $ID" >&2; exit 1; }
    load "$FILE"
    STATUS="CANCELED"
    save "$FILE"
    mv "$FILE" "$WIRE_CANCELED/${ID}.canceled"
    echo "$(date '+%F %T') | $ID | CANCELED | reason=$REASON" >> "$WIRE_HISTORY"
    echo "Canceled $ID"
    ;;

  release)
    # release ID APPROVER
    init_dirs
    ID="$2"; APPROVER="$3"
    FILE="$WIRE_QUEUE/$ID"
    [ -f "$FILE" ] || { echo "Not found: $ID" >&2; exit 1; }
    load "$FILE"
    if [ "$APPROVER" = "$MAKER" ]; then
      echo "Approver cannot equal maker" >&2; exit 1
    fi
    STATUS="RELEASED"
    save "$FILE"
    mv "$FILE" "$WIRE_RELEASED/${ID}.released"
    # print stub
    hv=NO
    awk "BEGIN{ if ($AMT+0 >= $HIGH_VALUE_THRESHOLD+0) print \"YES\"; else print \"NO\" }" >/dev/null 2>&1 || true
    form="$WIRE_FORMS/${ID}.txt"
    cat > "$form" <<EOF
INITECH WIRE TRANSFER REQUEST (Fedwire Stub)
ID: $ID
Debit: $DACC
Credit: $CNAME / $CABA / $CACC
Amount: $AMT
Type: $TYPE
Memo: ${MEMO:-N/A}
OFAC: $OFAC
Maker: $MAKER
Approver: $APPROVER
Status: $STATUS
EOF
    echo "$(date '+%F %T') | $ID | RELEASED | approver=$APPROVER" >> "$WIRE_HISTORY"
    echo "Released $ID (form: $form)"
    ;;

  print)
    init_dirs
    ID="$2"
    for f in "$WIRE_QUEUE/$ID" "$WIRE_RELEASED/${ID}.released"; do
      [ -f "$f" ] && { load "$f"; echo "$WIRE_FORMS/${ID}.txt"; exit 0; }
    done
    echo "Not found: $ID" >&2; exit 1
    ;;

  history)
    init_dirs
    history
    ;;

  selftest)
    # end-to-end quick test
    init_dirs
    echo "Adding two wires..."
    W1=$(sh "$0" add "100111222" "John Garcia" "026009593" "123456789" "2500.00" DOMESTIC "Invoice 42" "$(date +%F)" tester1)
    W2=$(sh "$0" add "200222333" "Ivan Ivanov" "026009593" "987654321" "15000.00" DOMESTIC "Payroll batch" "$(date +%F)" tester2)
    echo "Pending:"; sh "$0" list
    echo "Amend $W1 amount to 3000.00"; sh "$0" amend "$W1" AMT 3000.00
    echo "Release $W1 with approver checker1"; sh "$0" release "$W1" checker1
    echo "Cancel $W2"; sh "$0" cancel "$W2" "User request"
    echo "History:"; sh "$0" history
    ;;

  *)
    echo "Usage: $0 {init|add|list|amend|cancel|release|print|history|selftest}" >&2
    exit 1
    ;;
esac
