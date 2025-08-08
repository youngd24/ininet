#!/usr/bin/env python3
import os
import random
import datetime

# Define the date range
start_date = datetime.date(1996, 1, 1)
end_date = datetime.date(1998, 12, 31)
date_range_days = (end_date - start_date).days

# List all files in the current directory
files = [f for f in os.listdir('.') if os.path.isfile(f)]

for filename in files:
    # Skip if it's already in the TPS format and ends with .pdf
    if filename.startswith("TPS-") and filename.lower().endswith(".pdf"):
        continue

    while True:
        # Generate a random date in the range
        random_days = random.randint(0, date_range_days)
        random_date = start_date + datetime.timedelta(days=random_days)
        date_str = random_date.strftime("%Y-%m-%d")

        # Create the new filename
        new_filename = f"TPS-{date_str}.pdf"

        # Ensure it's unique
        if not os.path.exists(new_filename):
            break

    # Rename the file
    os.rename(filename, new_filename)
    print(f"Renamed '{filename}' -> '{new_filename}'")
