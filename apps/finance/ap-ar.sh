#!/usr/bin/bash

# Title and company name
TITLE="INITECH Financial Systems"
BACKTITLE="INITECH - Accounts Payable / Receivable Dashboard"

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
            1)
                dialog --title "Add Customer" --msgbox "Customer add form would go here." 10 50
                ;;
            2)
                dialog --title "Edit Customer" --msgbox "Customer edit screen would go here." 10 50
                ;;
            3)
                dialog --title "Delete Customer" --msgbox "Customer delete confirmation would go here." 10 50
                ;;
            4)
                dialog --title "View Customers" --msgbox "Customer list would be displayed here." 10 50
                ;;
            5)
                break
                ;;
            *)
                dialog --title "Error" --msgbox "Invalid option. Please try again." 7 50
                ;;
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

clear

