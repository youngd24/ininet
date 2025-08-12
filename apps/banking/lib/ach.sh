#!/usr/local/bin/bash
# ACH Module for ININET Banking System
# Solaris 7 + bash 4.1.0 + dialog 1.0  |  Ubuntu 24 + bash 5.2 + dialog 1.3

# Source core functions
# Note: This will be sourced from the main script, so core.sh is already available

# -----------------------------
# ACH Functions
# -----------------------------

# ACH: Receive (view inbox)
ach_receive() {
  LIST=$(ls -1 "$ACH_INBOX" 2>/dev/null)
  [ -z "$LIST" ] && LIST="(empty)"
  "$DIALOG" --backtitle "$BACKTITLE" --title "ACH Inbox" --msgbox "$LIST" 18 70
}

# ACH: Originate (queue NACHA file)
ach_originate() {
  ask_input "ACH Origination" "Path to NACHA file to queue for send:" "" || return 1
  SRC=$(cat "$TMP.in")
  if [ -f "$SRC" ]; then
    BASENAME=$(basename "$SRC")
    cp "$SRC" "$ACH_OUTBOX/$BASENAME" && \
      log_op "ACH" "Queued for send: $BASENAME" && \
      msg "Queued: $BASENAME"
  else
    msg "File not found."
  fi
}

# ACH: Returns (log code & note)
ach_returns() {
  ask_input "ACH Return" "Enter Return Code (e.g., R01-R85):" "R01" || return 1
  RC=$(cat "$TMP.in")
  ask_input "ACH Return" "Related Account/Trace (free text):" "" || return 1
  NOTE=$(cat "$TMP.in")
  log_op "ACH_RETURN" "$RC | $NOTE"
  msg "Return logged."
}

# ACH Batch: Post Incoming (stub)
ach_post_incoming() {
  CNT=$(ls -1 "$ACH_INBOX" 2>/dev/null | wc -l | $AWK '{print $1}')
  log_op "ACH_POST" "Posted $CNT incoming files (stub)."
  msg "Simulated posting of $CNT incoming ACH files."
}

# ACH Batch: Send Outgoing (stub)
ach_send_outgoing() {
  CNT=$(ls -1 "$ACH_OUTBOX" 2>/dev/null | wc -l | $AWK '{print $1}')
  log_op "ACH_SEND" "Transmitted $CNT outgoing files (stub)."
  msg "Simulated transmission of $CNT outgoing files."
}
