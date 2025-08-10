#TABLE OF CONTENTS


1. ##INTRODUCTION

Welcome to the INITECH Banking System — the late-90s solution for ACH, Wires, and
a few “Special Projects” that Finance doesn’t ask about.

This build is for demonstration purposes only at Vintage Computer Fest.
No real money moves, but a lot of fictional pennies might.


2. SYSTEM REQUIREMENTS

* Operating System: Solaris 7 (SunOS 5.7)
* Shell: /usr/local/bin/bash (v2.0+)
* UI: dialog 1.0 (or fallback text menus)
* Disk Space: 5MB (plus 10MB for “document imaging” that’s really text files)
* Human Factors:
  \*\* 1 bored sysadmin
  \*\* 1 middle manager who says “Yeahhhh…” a lot


3. DIRECTORY STRUCTURE

```
   /export/banking
   ├── ach/                # ACH payment files (incoming/outgoing)
   ├── wires/              # Wire transfer queue
   ├── log/                # Operational and "Special Projects" logs
   ├── docs/               # Scanned forms \& signature cards
   ├── state/              # Flat-file databases (SQL licenses cost money)
   └── special\_projects/   # Rounding configs \& skim history
```

4. OPERATING INSTRUCTIONS
   
Run the VCF Control Panel:

```./vcf_control.sh```

Options include:

* Reset to Baseline – wipe all traces of shenanigans, reseed cast \& data.
* Seed Baseline – add default customers (Peter, Samir, Milton, etc.).
* Run Demo Tour – pre-load jokes, suspicious logs, and a fake wire.
* Launch INITECH TUI – main menu for banking ops.
* View Audit Log – see what Compliance will yell about.

5. SPECIAL ACCESS CODES

* TPS → Unlocks Special Projects menu for rounding-error skims.
* 911 (wire amount) → Milton panic mode: locks down the terminal.

6. COMPLIANCE NOTES

* OFAC checks are manual. Keep a paper list.
* CTR filing done with actual pens.
* Any resemblance to real banks is purely coincidental… except the funny parts.

7. EASTER EGGS \& KNOWN “FEATURES”

* PC LOAD LETTER LLC – escrow account \& frequent payee.
* TPS Consulting LLC – recipient of fractions-of-a-cent skims.
* Signature cards feature faint red stapler imprints.
* Wire fax coversheets say “Yeahhhh” in Comic Sans.

©1999 INITECH Corp. – Bringing You \& Us Together™
Printed in the USA on recycled TPS reports.
