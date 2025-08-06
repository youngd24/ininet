#!/usr/bin/bash

# Title and company name
TITLE="INITECH Financial Systems"
BACKTITLE="INITECH - Accounts Payable / Receivable Dashboard"

# Path to customer database
CUSTOMER_DB="/export/accounting/customers.db"
mkdir -p /export/accounting
touch "$CUSTOMER_DB"

# Function to add a customer
function add_customer() {
    NAME=$(dialog --inputbox "Enter Customer Name:" 8 50 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    ADDRESS=$(dialog --inputbox "Enter Address:" 8 50 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    PHONE=$(dialog --inputbox "Enter Phone Number:" 8 50 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    LAST_ID=$(awk -F'|' 'END {print $1+1}' "$CUSTOMER_DB")
    [ -z "$LAST_ID" ] && LAST_ID=1

    echo "$LAST_ID|$NAME|$ADDRESS|$PHONE" >> "$CUSTOMER_DB"
    dialog --msgbox "Customer added successfully." 7 50
}

# Function to view customers
function view_customers() {
    if [ ! -s "$CUSTOMER_DB" ]; then
        dialog --msgbox "No customers found." 7 50
        return
    fi
    dialog --title "Customer List" --textbox "$CUSTOMER_DB" 20 70
}

# Function to edit a customer
function edit_customer() {
    if [ ! -s "$CUSTOMER_DB" ]; then
        dialog --msgbox "No customers to edit." 7 50
        return
    fi

    CUST_LIST=$(awk -F'|' '{printf "%s \"%s\"\n", $1, $2}' "$CUSTOMER_DB")
    ID=$(eval dialog --menu \"Select customer to edit:\" 20 60 15 $CUST_LIST 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    OLD_LINE=$(grep "^$ID|" "$CUSTOMER_DB")
    OLD_NAME=$(echo "$OLD_LINE" | cut -d'|' -f2)
    OLD_ADDR=$(echo "$OLD_LINE" | cut -d'|' -f3)
    OLD_PHONE=$(echo "$OLD_LINE" | cut -d'|' -f4)

    NAME=$(dialog --inputbox "Edit Name:" 8 50 "$OLD_NAME" 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return
    ADDRESS=$(dialog --inputbox "Edit Address:" 8 50 "$OLD_ADDR" 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return
    PHONE=$(dialog --inputbox "Edit Phone:" 8 50 "$OLD_PHONE" 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    sed -i "/^$ID|/d" "$CUSTOMER_DB"
    echo "$ID|$NAME|$ADDRESS|$PHONE" >> "$CUSTOMER_DB"
    sort -t'|' -k1,1n "$CUSTOMER_DB" -o "$CUSTOMER_DB"

    dialog --msgbox "Customer updated successfully." 7 50
}

# Function to delete a customer
function delete_customer() {
    if [ ! -s "$CUSTOMER_DB" ]; then
        dialog --msgbox "No customers to delete." 7 50
        return
    fi

    CUST_LIST=$(awk -F'|' '{printf "%s \"%s\"\n", $1, $2}' "$CUSTOMER_DB")
    ID=$(eval dialog --menu \"Select customer to delete:\" 20 60 15 $CUST_LIST 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return

    NAME=$(awk -F'|' -v id="$ID" '$1==id {print $2}' "$CUSTOMER_DB")
    dialog --yesno "Are you sure you want to delete \"$NAME\"?" 7 50
    if [ $? -eq 0 ]; then
        sed -i "/^$ID|/d" "$CUSTOMER_DB"
        dialog --msgbox "Customer deleted successfully." 7 50
    fi
}

# Customer Master sub-menu function
function customer_master_menu() {
    while true; do
        SUBCHOICE=$(dialog --clear \
            --backtitle "$BACKTITLE" \
            --title "Maintain Customer Master" \
            --menu "Select a customer master function" 15 60 5 \
            1 "Add Customer" \
            2 "Edit Customer" \
            3 "Delete Customer" \
            4 "View Customers" \
            5 "Return to Main Menu" \
            3>&1 1>&2 2>&3)

        clear
        case $SUBCHOICE in
            1) add_customer ;;
            2) edit_customer ;;
            3) delete_customer ;;
            4) view_customers ;;
            5) break ;;
            *) dialog --title "Error" --msgbox "Invalid option. Please try again." 7 50 ;;
        esac
    done
}

# Main menu loop
while true; do
    CHOICE=$(dialog --clear \
        --backtitle "$BACKTITLE" \
        --title "$TITLE" \
        --menu "Main Menu - Select an Option" 18 60 7 \
        1 "View Accounts Payable" \
        2 "Enter Vendor Invoice" \
        3 "View Accounts Receivable" \
        4 "Enter Customer Payment" \
        5 "Maintain Customer Master" \
        6 "Generate Reports" \
        7 "Exit" \
        3>&1 1>&2 2>&3)

    clear
    case $CHOICE in
        1)
            dialog --title "Accounts Payable" --msgbox "Displaying list of unpaid vendor invoices..." 10 50
            ;;
        2)
            dialog --title "Enter Vendor Invoice" --msgbox "Invoice entry form would go here." 10 50
            ;;
        3)
            dialog --title "Accounts Receivable" --msgbox "Displaying list of outstanding customer payments..." 10 50
            ;;
        4)
            dialog --title "Enter Customer Payment" --msgbox "Payment entry form would go here." 10 50
            ;;
        5)
            customer_master_menu
            ;;
        6)
            dialog --title "Reports" --msgbox "Generating financial reports..." 10 50
            ;;
        7)
            dialog --title "Exit" --msgbox "Thank you for using INITECH Financial Systems." 7 50
            break
            ;;
        *)
            dialog --title "Error" --msgbox "Invalid option. Please try again." 7 50
            ;;
    esac
done

