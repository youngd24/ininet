#!/usr/local/bin/bash
# Core infrastructure for ININET Banking System
# Solaris 7 + bash 4.1.0 + dialog 1.0  |  Ubuntu 24 + bash 5.2 + dialog 1.3

# -----------------------------
# Config / Environment
# -----------------------------
TITLE="ININET BANK MANAGEMENT SYSTEM"
BACKTITLE="ININET - Innovation + Technology"
DATA_ROOT="/export/banking"
LOG_DIR="$DATA_ROOT/log"
ACH_INBOX="$DATA_ROOT/ach/incoming"       # batch (received)
ACH_OUTBOX="$DATA_ROOT/ach/outgoing"      # batch (to send)
WIRE_QUEUE="$DATA_ROOT/wires/pending"     # manual review/release
WIRE_RELEASED="$DATA_ROOT/wires/released" # archive
WIRE_CANCELED="$DATA_ROOT/wires/canceled" # archive
WIRE_FORMS="$DATA_ROOT/wires/forms"       # printable stubs
DOC_STORE="$DATA_ROOT/docs"               # paper/microfilm placeholder
STATE_DIR="$DATA_ROOT/state"              # misc state
PROJECT_DIR="$DATA_ROOT/special_projects" # Peter's playground
WIRE_HISTORY="$DATA_ROOT/wires/wires.log" # consolidated history
OFAC_LIST="$STATE_DIR/ofac_list.txt"      # simple list (one name/keyword per line)
HIGH_VALUE_THRESHOLD="10000.00"           # demo threshold for extra confirm

## Prefer system tools if present; include Solaris XPG4 fallbacks
if command -v gawk >/dev/null 2>&1; then
  AWK=$(command -v gawk)
elif [ -x /usr/local/bin/gawk ]; then
  AWK=/usr/local/bin/gawk
elif [ -x /usr/xpg4/bin/awk ]; then
  AWK=/usr/xpg4/bin/awk
else
  AWK=/usr/bin/awk
fi

if [ -x /usr/xpg4/bin/grep ]; then
  GREP=/usr/xpg4/bin/grep
else
  GREP=/usr/bin/grep
fi

if command -v dialog >/dev/null 2>&1; then
  DIALOG=$(command -v dialog)
elif [ -x /usr/local/bin/dialog ]; then
  DIALOG=/usr/local/bin/dialog
else
  DIALOG=/usr/bin/dialog
fi

# tail: prefer XPG4 on Solaris for -n support
if [ -x /usr/xpg4/bin/tail ]; then
  TAILBIN=/usr/xpg4/bin/tail
else
  TAILBIN=/usr/bin/tail
fi

# Temporary file for dialog input/output (no mktemp on stock Solaris 7)
TMP="/tmp/initech.$$"
trap 'rm -f "$TMP"*; clear' EXIT HUP INT TERM

# -----------------------------
# Helpers
# -----------------------------
die() { echo "ERROR: $*" >&2; exit 1; }

# =============================
# Y2K Config / Helpers (Solaris 7 + Ubuntu 24 compatible)
# =============================
# Windowing cutoff: 00-69 => 2000-2069, 70-99 => 1970-1999
: "${Y2K_LOW_CUTOFF:=69}"

# Optional "fake clock" for rollover testing; set FAKE_TODAY=YYYYMMDD in env to simulate
date_ymd_now() {
  if [ -n "$FAKE_TODAY" ]; then
    echo "$FAKE_TODAY"
  else
    date '+%Y%m%d'
  fi
}

# Normalize common date forms to YYYYMMDD using awk only
# Supports: YYYYMMDD, YYMMDD, MM/DD/YY, MM-DD-YY, YYYY-MM-DD, YYYY/MM/DD
normalize_date_ymd() {
  # portable awk (prefer XPG4 if $AWK is set by the script)
  _AWK="${AWK:-awk}"
  echo "$1" | "$_AWK" -v cut="$Y2K_LOW_CUTOFF" '
  function y2k_year(yy,  n){ n=yy+0; return (n<=cut)?2000+n:1900+n }
  function valid(y,m,d,  ml,leap){
    if (y<1900 || y>2099) return 0
    if (m<1||m>12) return 0
    leap = ((y%4==0 && y%100!=0) || (y%400==0)) ? 1 : 0
    ml = (m==1||m==3||m==5||m==7||m==8||m==10||m==12)?31:(m==4||m==6||m==9||m==11)?30:(leap?29:28)
    return (d>=1 && d<=ml)
  }
  {
    gsub(/[[:space:]]+/,"",$0)
    s=$0
    # YYYYMMDD
    if (s ~ /^[0-9]{8}$/) {
      y=substr(s,1,4); m=substr(s,5,2); d=substr(s,7,2)
      if (valid(y,m,d)) { printf("%04d%02d%02d\n",y,m,d); exit }
    }
    # YYMMDD
    if (s ~ /^[0-9]{6}$/) {
      y=y2k_year(substr(s,1,2)); m=substr(s,3,2); d=substr(s,5,2)
      if (valid(y,m,d)) { printf("%04d%02d%02d\n",y,m,d); exit }
    }
    # YYYY-MM-DD or YYYY/MM/DD
    if (s ~ /^[0-9]{4}[-\/][0-9]{2}[-\/][0-9]{2}$/) {
      y=substr(s,1,4); m=substr(s,6,2); d=substr(s,9,2)
      if (valid(y,m,d)) { printf("%04d%02d%02d\n",y,m,d); exit }
    }
    # MM/DD/YY or MM-DD-YY
    if (s ~ /^[0-9]{2}[-\/][0-9]{2}[-\/][0-9]{2}$/) {
      m=substr(s,1,2); d=substr(s,4,2); yy=substr(s,7,2); y=y2k_year(yy)
      if (valid(y,m,d)) { printf("%04d%02d%02d\n",y,m,d); exit }
    }
    # If nothing matched, print empty
    print ""
  }'
}

# Return 0 if valid YYYYMMDD, else 1
validate_yyyymmdd() {
  local d="$1"
  [ ${#d} -eq 8 ] || return 1
  _AWK="${AWK:-awk}"
  echo "$d" | "$_AWK" '
  function valid(y,m,d,ml,leap){
    if (y<1900 || y>2099) return 0
    if (m<1||m>12) return 0
    leap = ((y%4==0 && y%100!=0) || (y%400==0)) ? 1 : 0
    ml = (m==1||m==3||m==5||m==7||m==8||m==10||m==12)?31:(m==4||m==6||m==9||m==11)?30:(leap?29:28)
    return (d>=1 && d<=ml)
  }
  {
    y=substr($0,1,4)+0; m=substr($0,5,2)+0; d=substr($0,7,2)+0
    if (valid(y,m,d)) exit 0; else exit 1
  '
}

# Harden append points to ensure valid dates when using simulated clock
ensure_today_or_default() {
  local _d
  _d="$(date_ymd_now)"
  if ! validate_yyyymmdd "$_d"; then
    _d="$(date '+%Y%m%d')"
  fi
  echo "$_d"
}

# -----------------------------
# Environment Setup
# -----------------------------
ensure_env() {
  [ -x "$DIALOG" ] || die "dialog(1) not found. Install dialog in /usr/local/bin."
  for d in "$DATA_ROOT" "$LOG_DIR" "$ACH_INBOX" "$ACH_OUTBOX" "$WIRE_QUEUE" \
           "$DOC_STORE" "$STATE_DIR" "$PROJECT_DIR" "$WIRE_RELEASED" "$WIRE_CANCELED" \
           "$WIRE_FORMS"; do
    [ -d "$d" ] || mkdir -p "$d" || die "Cannot create $d"
  done

  # Preserve existing data/logs; only create if absent
  [ -f "$STATE_DIR/accounts.db" ] || : > "$STATE_DIR/accounts.db"
  [ -f "$LOG_DIR/ops.log" ]       || : > "$LOG_DIR/ops.log"
  [ -f "$WIRE_HISTORY" ]          || : > "$WIRE_HISTORY"

  # seed OFAC list placeholder if absent
  if [ ! -f "$OFAC_LIST" ]; then
    cat > "$OFAC_LIST" <<EOF
# Simple OFAC name/keyword list (demo)
# One entry per line; case-insensitive substring match
GARCIA
IVANOV
PC LOAD LETTER LLC
EOF
  fi
}

# -----------------------------
# Logging Functions
# -----------------------------
log_op() {
  # log_op "category" "message"
  printf '%s | %s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" >> "$LOG_DIR/ops.log"
}

log_wire() {
  # log_wire "WIRE_ID" "event" "detail"
  printf '%s | %s | %s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" "$3" >> "$WIRE_HISTORY"
}

# -----------------------------
# Utility Functions
# -----------------------------
to_upper() {
  echo "$1" | $AWK '{print toupper($0)}'
}

compare_money_ge() {
  # usage: compare_money_ge A B ; return 0 if A >= B else 1
  echo | $AWK -v a="$1" -v b="$2" 'BEGIN{ if (a+0 >= b+0) exit 0; else exit 1 }'
}
