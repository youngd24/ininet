#!/usr/bin/python3
from datetime import date, timedelta, datetime
import random
import re
import sys
import csv
import argparse

# Try to import Faker gracefully
try:
    from faker import Faker
except ImportError:
    print("Error: The 'faker' module is not installed. Please install it using 'pip install faker' or your OS package manager.")
    sys.exit(1)

# Initialize Faker instance
fake = Faker()

# ---- Configurable date boundaries ----
DATE_START = date(1996, 1, 1)
DATE_END = date(1998, 12, 31)
TEST_DATE_END = date(1999, 1, 1)
TARGET_DATE_END = date(1999, 1, 1)

# Error message bounds
ERROR_MAX = 100

# Allowed late-90s languages
LATE_90S_LANGS = [
    'C', 'C++', 'Java', 'Perl', 'COBOL', 'Visual Basic', 'Delphi', 'JavaScript', 'Tcl', 'PHP'
]

# Technical manuals from the 90s
TECH_MANUALS_90S = [
    'Windows 95 Resource Kit',
    'Programming with Visual Basic 4.0',
    'Mastering Turbo C++',
    'The Waite Group’s C++ Programming',
    'Perl 5 for Dummies',
    'Java in a Nutshell',
    'COBOL for the 21st Century',
    'Inside Windows NT',
    'Unix System V Release 4 Administrator’s Guide',
    'Teach Yourself JavaScript in 21 Days'
]


def _iso(d: date) -> str:
    """Convert a date object to an ISO-8601 formatted string."""
    return d.isoformat()


def generate_fake_data():
    """Generate one fake record with constrained dates and realistic late-90s data."""
    return {
        "Prepared_By": fake.name(),
        "Date": _iso(fake.date_between(start_date=DATE_START, end_date=DATE_END)),
        "Device-Program_Type": fake.bs(),
        "Product_Code": fake.bothify(text='???-#####'),
        "Customer": fake.company(),
        "Vendor": fake.company(),
        "Due_Date": _iso(fake.date_between(start_date=DATE_START, end_date=DATE_END)),
        "Data_Loss": random.choice([True, False]),
        "Test_Date": _iso(fake.date_between(start_date=DATE_START, end_date=TEST_DATE_END)),
        "Target_Run_Date": _iso(fake.date_between(start_date=DATE_START, end_date=TARGET_DATE_END)),
        "Program_Run_Time": fake.time(),
        "Reference_Guide": random.choice(TECH_MANUALS_90S),
        "Program_Language": random.choice(LATE_90S_LANGS),
        "Number_of_Error_Messages": random.randint(0, ERROR_MAX),
    }


def _parse_iso(d: str) -> date:
    """Parse an ISO-8601 date string to a date object."""
    return datetime.fromisoformat(d).date()


def run_tests(sample_size: int = 100) -> None:
    """Run basic invariants and sanity checks on generated data."""
    code_pattern = re.compile(r'^[A-Za-z]{3}-\d{5}$')

    for _ in range(sample_size):
        row = generate_fake_data()

        # Type checks
        assert isinstance(row["Prepared_By"], str)
        assert isinstance(row["Device-Program_Type"], str)
        assert isinstance(row["Product_Code"], str)
        assert isinstance(row["Customer"], str)
        assert isinstance(row["Vendor"], str)
        assert isinstance(row["Data_Loss"], bool)
        assert isinstance(row["Program_Run_Time"], str)
        assert isinstance(row["Reference_Guide"], str)
        assert isinstance(row["Program_Language"], str)
        assert isinstance(row["Number_of_Error_Messages"], int)

        # Date bounds checks
        d_date = _parse_iso(row["Date"])
        d_due = _parse_iso(row["Due_Date"])
        d_test = _parse_iso(row["Test_Date"])
        d_target = _parse_iso(row["Target_Run_Date"])

        assert DATE_START <= d_date <= DATE_END, f"Date out of range: {d_date}"
        assert DATE_START <= d_due <= DATE_END, f"Due_Date out of range: {d_due}"
        assert DATE_START <= d_test <= TEST_DATE_END, f"Test_Date out of range: {d_test}"
        assert DATE_START <= d_target <= TARGET_DATE_END, f"Target_Run_Date out of range: {d_target}"

        # Additional sanity checks
        assert row["Reference_Guide"] in TECH_MANUALS_90S
        assert 0 <= row["Number_of_Error_Messages"] <= ERROR_MAX
        datetime.strptime(row["Program_Run_Time"], "%H:%M:%S")
        assert row["Program_Language"] in LATE_90S_LANGS
        assert code_pattern.match(row["Product_Code"]) is not None


def generate_fake_rows(n: int = 5):
    """Generate multiple fake records."""
    return [generate_fake_data() for _ in range(n)]


def output_csv(records):
    """Output records as CSV with a header row."""
    writer = csv.DictWriter(sys.stdout, fieldnames=records[0].keys())
    writer.writeheader()
    writer.writerows(records)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate fake TPS report data.")
    parser.add_argument("num_samples", type=int, nargs="?", default=10, help="Number of samples to generate (default: 10)")
    parser.add_argument("--format", choices=["text", "csv"], default="text", help="Output format (default: text)")
    args = parser.parse_args()

    run_tests(sample_size=50)
    records = generate_fake_rows(args.num_samples)

    if args.format == "csv":
        output_csv(records)
    else:
        print("All tests passed. Sample output:\n")
        for i, row in enumerate(records, start=1):
            print(f"--- Record {i} ---")
            for k, v in row.items():
                print(f"{k}: {v}")
            print()
