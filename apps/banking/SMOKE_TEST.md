# INITECH Banking (Portable) — Wire Desk Enhancements

This package contains:
- `initech_bank_mvp.sh` — TUI app (Solaris 7 bash 4.1.0 + dialog 1.0, and Ubuntu 24 bash 5.2 + dialog 1.3)
- `wire_cli.sh` — non-interactive CLI harness for quick testing (no dialog needed)
- `OFAC sample` — seeded automatically at first run under `/export/banking/state/ofac_list.txt`

## Install (Solaris 7)
1. Ensure `bash` 4.1.0 is at `/usr/local/bin/bash` and `dialog` 1.0 at `/usr/local/bin/dialog`.
2. `chmod +x initech_bank_mvp.sh wire_cli.sh`
3. Run the app: `./initech_bank_mvp.sh`

## Install (Ubuntu 24)
1. `sudo apt install dialog`
2. Optionally uncomment the portable launcher line at the top of the script.
3. `chmod +x initech_bank_mvp.sh wire_cli.sh`
4. `./initech_bank_mvp.sh`

## File Layout
All data lives under `/export/banking`:
```
/export/banking/
  ach/{incoming,outgoing}
  wires/{pending,released,canceled,forms}
  state/
  log/
```

## Quick Self-Test (no dialog needed)
```
# One-time init
./wire_cli.sh init

# End-to-end
./wire_cli.sh selftest

# Or step-by-step
ID=$(./wire_cli.sh add "100111222" "John Garcia" "026009593" "123456789" "2500.00" DOMESTIC "Invoice 42" 1999-07-16 maker1)
./wire_cli.sh list
./wire_cli.sh amend "$ID" AMT 3000.00
./wire_cli.sh release "$ID" checker1
./wire_cli.sh history
```

## Notes
- OFAC matching is a simple case-insensitive substring demo; edit `/export/banking/state/ofac_list.txt`.
- The TUI app enforces dual control; CLI harness does minimal checks for convenience.
- Forms are written to `/export/banking/wires/forms/ID.txt`.
