#!/usr/bin/env python3
"""
Generate a T.P.S. REPORT cover sheet PDF with tweaked spacing using Times New Roman font and Initech logo from disk.
"""
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from reportlab.lib.units import inch
from reportlab.lib.utils import ImageReader
import argparse
import csv
from pathlib import Path

PAGE_WIDTH, PAGE_HEIGHT = letter
MARGIN_L, MARGIN_R, MARGIN_T, MARGIN_B = (0.9 * inch, 0.9 * inch, 0.25 * inch, 0.9 * inch)
CONTENT_W = PAGE_WIDTH - MARGIN_L - MARGIN_R
LABEL_FONT = "Times-Roman"
TITLE_FONT = "Times-Bold"
ROW_GAP = 30

CSV_HEADERS = [
    "Prepared_By",
    "Date",
    "Device-Program_Type",
    "Product_Code",
    "Customer",
    "Vendor",
    "Due_Date",
    "Data_Loss",
    "Test_Date",
    "Target_Run_Date",
    "Program_Run_Time",
    "Reference_Guide",
    "Program_Language",
    "Number_of_Error_Messages",
]

CSV_TO_INTERNAL = {
    "Prepared_By": "prepared_by",
    "Date": "date",
    "Device-Program_Type": "device_program_type",
    "Product_Code": "product_code",
    "Customer": "customer",
    "Vendor": "vendor",
    "Due_Date": "due_date",
    "Data_Loss": "data_loss",
    "Test_Date": "test_date",
    "Target_Run_Date": "target_run_date",
    "Program_Run_Time": "program_run_time",
    "Reference_Guide": "reference_guide",
    "Program_Language": "program_language",
    "Number_of_Error_Messages": "num_error_messages",
    "Comments": "comments",
}

def y_from_top(offset):
    return PAGE_HEIGHT - MARGIN_T - offset

def draw_centered(c, text, y, size, font=TITLE_FONT):
    c.setFont(font, size)
    c.drawCentredString(PAGE_WIDTH / 2.0, y, text)

def draw_label_line(c, label, y, label_w, line_w, value=""):
    c.setFont(LABEL_FONT, 12)
    c.drawString(MARGIN_L, y, label)
    line_y = y - 12
    start_x = MARGIN_L + label_w + 6
    c.line(start_x, line_y, start_x + line_w, line_y)
    if value:
        c.drawString(start_x + 2, line_y + 3, value)

def draw_two_label_line(c, left, right, y):
    l_label, l_w, l_line, l_val = left
    r_label, r_w, r_line, r_val = right
    c.setFont(LABEL_FONT, 12)
    c.drawString(MARGIN_L, y, l_label)
    l_line_y = y - 12
    l_start_x = MARGIN_L + l_w + 6
    c.line(l_start_x, l_line_y, l_start_x + l_line, l_line_y)
    if l_val:
        c.drawString(l_start_x + 2, l_line_y + 3, l_val)
    r_x = MARGIN_L + CONTENT_W / 2 + 16
    c.drawString(r_x, y, r_label)
    r_line_y = y - 12
    r_start_x = r_x + r_w + 6
    c.line(r_start_x, r_line_y, r_start_x + r_line, r_line_y)
    if r_val:
        c.drawString(r_start_x + 2, r_line_y + 3, r_val)

def render_cover(output_path, data):
    c = canvas.Canvas(output_path, pagesize=letter)
    logo_path = Path("initech.png")
    if logo_path.exists():
        try:
            logo_img = ImageReader(str(logo_path))
            logo_width = 2.5 * inch
            logo_height = logo_width * 0.4
            top_offset = 0.0 * inch
            c.drawImage(
                logo_img,
                (PAGE_WIDTH - logo_width) / 2,
                PAGE_HEIGHT - MARGIN_T - logo_height - top_offset,
                width=logo_width,
                height=logo_height,
                preserveAspectRatio=True,
                mask='auto'
            )
        except Exception as e:
            print(f"Warning: could not load logo from file: {e}")
    else:
        print("Warning: initech.png not found, skipping logo.")

    draw_centered(c, "T.P.S. REPORT", y_from_top(1.7 * inch), 40)
    draw_centered(c, "C O V E R  S H E E T", y_from_top(1.5 * inch + 40), 16)
    y = y_from_top(2.7 * inch)
    draw_two_label_line(c, ("Prepared By:", 90, 240, data.get("prepared_by", "")), ("Date:", 32, 120, data.get("date", "")), y)
    y -= ROW_GAP
    draw_label_line(c, "Device/Program Type:", y, 140, CONTENT_W - 150, data.get("device_program_type", ""))
    y -= ROW_GAP
    draw_two_label_line(c, ("Product Code:", 90, 150, data.get("product_code", "")), ("Customer:", 70, 200, data.get("customer", "")), y)
    y -= ROW_GAP
    draw_label_line(c, "Vendor:", y, 50, CONTENT_W - 60, data.get("vendor", ""))
    y -= ROW_GAP
    draw_two_label_line(c, ("Due Date:", 64, 140, data.get("due_date", "")), ("Data Loss:", 74, 160, data.get("data_loss", "")), y)
    y -= ROW_GAP
    draw_two_label_line(c, ("Test Date:", 66, 140, data.get("test_date", "")), ("Target Run Date:", 118, 160, data.get("target_run_date", "")), y)
    y -= ROW_GAP
    draw_two_label_line(c, ("Program Run Time:", 120, 120, data.get("program_run_time", "")), ("Reference Guide:", 110, 220, data.get("reference_guide", "")), y)
    y -= ROW_GAP
    draw_two_label_line(c, ("Program Language:", 120, 120, data.get("program_language", "")), ("Number of Error Messages:", 190, 80, data.get("num_error_messages", "")), y)
    y -= ROW_GAP + 8
    c.setFont(LABEL_FONT, 12)
    c.drawString(MARGIN_L, y, "Comments:")
    box_top = y - 14
    box_height = 90
    c.rect(MARGIN_L, box_top - box_height, CONTENT_W, box_height)
    comments = data.get("comments", [])
    if isinstance(comments, str):
        comments = [comments]
    ty = box_top - 18
    for line in comments[:4]:
        c.drawString(MARGIN_L + 8, ty, line)
        ty -= 18
    c.setFont(TITLE_FONT, 14)
    c.drawCentredString(PAGE_WIDTH / 2.0, MARGIN_B - 12, "C O N F I D E N T I A L")
    c.showPage()
    c.save()

def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--input_file", required=True, help="CSV input file containing field values")
    return p.parse_args()

def csv_row_to_data(row: dict) -> dict:
    data = {}
    for k_csv, v in row.items():
        if k_csv not in CSV_TO_INTERNAL:
            continue
        key = CSV_TO_INTERNAL[k_csv]
        data[key] = (v or "").strip()
    if "comments" in data and isinstance(data["comments"], str) and data["comments"].strip():
        data["comments"] = [data["comments"]]
    else:
        data["comments"] = []
    return data

if __name__ == "__main__":
    args = parse_args()
    csv_path = Path(args.input_file)

    if csv_path.exists():
        with csv_path.open(newline="", encoding="utf-8-sig") as f:
            reader = csv.DictReader(f)
            missing = [h for h in CSV_HEADERS if h not in reader.fieldnames]
            if missing:
                raise SystemExit(f"{args.input_file} is missing headers: {', '.join(missing)}")
            for idx, row in enumerate(reader, start=1):
                data = csv_row_to_data(row)
                date_str = data.get("date", "").replace("/", "-").replace(" ", "_")
                product_code = data.get("product_code", "").replace(" ", "_")
                out_name = f"TPS_{date_str}_{product_code}.pdf"
                render_cover(out_name, data)
                print(f"Wrote {out_name}")
    else:
        raise SystemExit(f"Input file {args.input_file} not found")
