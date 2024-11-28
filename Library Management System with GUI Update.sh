#!/bin/bash

LIBRARY_FILE="library.txt"
LIBRARIANS_FILE="librarians.txt"
LOG_FILE="library.log"

# Ensure necessary files exist
if [ ! -f "$LIBRARY_FILE" ]; then
    touch "$LIBRARY_FILE"
fi
if [ ! -f "$LIBRARIANS_FILE" ]; then
    echo "mahfuzur,5270" > $LIBRARIANS_FILE # Example librarian credentials
fi
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
fi

log_action() {
    echo "$(date): $1" >> $LOG_FILE
}

show_main_menu() {
    zenity --info --title="Welcome!" --text="Welcome to the Library Management System. Please select your role to proceed." --width=400
    choice=$(zenity --list --title="Library Management System" --column="Options" \
        "Librarian" "Student" "Exit" \
        --height=250 --width=300)
    case $choice in
        "Librarian") librarian_login ;;
        "Student") student_menu ;;
        "Exit") 
            zenity --info --title="Goodbye!" --text="Thank you for using the Library Management System. Goodbye!" --width=300
            exit 0 ;;
        *) zenity --error --text="Invalid choice!" ;;
    esac
}

librarian_login() {
    username=$(zenity --entry --title="Librarian Login" --text="Enter Username:")
    password=$(zenity --password --title="Librarian Login" --text="Enter Password:")

    if grep -q "^$username,$password" $LIBRARIANS_FILE; then
        zenity --info --text="Login successful!" --title="Login"
        log_action "Librarian '$username' logged in."
        librarian_menu
    else
        zenity --error --text="Login failed!" --title="Error"
    fi
}

librarian_menu() {
    while true; do
        choice=$(zenity --list --title="Librarian Menu" --column="Options" \
            "Add Book" "Edit Book" "Delete Book" "List Books" "Logout" \
            --height=250 --width=300)
        case $choice in
            "Add Book") add_book ;;
            "Edit Book") edit_book ;;
            "Delete Book") delete_book ;;
            "List Books") list_books ;;
            "Logout") break ;;
            *) zenity --error --text="Invalid choice!" ;;
        esac
    done
}

add_book() {
    book_id=$(zenity --entry --title="Add Book" --text="Enter Book ID:")
    [ -z "$book_id" ] && zenity --error --text="Book ID cannot be empty!" && return

    title=$(zenity --entry --title="Add Book" --text="Enter Book Title:")
    [ -z "$title" ] && zenity --error --text="Book Title cannot be empty!" && return

    author=$(zenity --entry --title="Add Book" --text="Enter Author Name:")
    [ -z "$author" ] && zenity --error --text="Author Name cannot be empty!" && return

    echo "$book_id,$title,$author" >> $LIBRARY_FILE
    log_action "Book added: ID=$book_id, Title=$title, Author=$author"
    zenity --info --text="Book added successfully!"
}

edit_book() {
    book_id=$(zenity --entry --title="Edit Book" --text="Enter Book ID to edit:")
    if grep -q "^$book_id," $LIBRARY_FILE; then
        new_title=$(zenity --entry --title="Edit Book" --text="Enter new Title:")
        new_author=$(zenity --entry --title="Edit Book" --text="Enter new Author:")
        sed -i "/^$book_id,/ s/.*/$book_id,$new_title,$new_author/" $LIBRARY_FILE
        log_action "Book edited: ID=$book_id, New Title=$new_title, New Author=$new_author"
        zenity --info --text="Book details updated successfully!"
    else
        zenity --error --text="Book ID not found!"
    fi
}

delete_book() {
    book_id=$(zenity --entry --title="Delete Book" --text="Enter Book ID to delete:")
    [ -z "$book_id" ] && zenity --error --text="Book ID cannot be empty!" && return

    if grep -q "^$book_id," $LIBRARY_FILE; then
        grep -v "^$book_id," $LIBRARY_FILE > temp_file && mv temp_file $LIBRARY_FILE
        log_action "Book deleted: ID=$book_id"
        zenity --info --text="Book deleted successfully!"
    else
        zenity --error --text="No book found with the given ID!"
    fi
}

list_books() {
    if [ ! -s $LIBRARY_FILE ]; then
        zenity --info --text="No books available in the library!"
        return
    fi

    books=$(awk -F, '{printf "%-10s %-20s %-20s %-15s\n", $1, $2, $3, ($4 ? "Checked Out" : "Available")}' $LIBRARY_FILE)
    formatted_books="Book ID   Title                Author              Status\n---------------------------------------------------------\n$books"
    echo -e "$formatted_books" | zenity --text-info --title="Book List" --width=500 --height=400
}

student_menu() {
    student_id=$(zenity --entry --title="Student Menu" --text="Enter your Student ID:")
    [ -z "$student_id" ] && zenity --error --text="Student ID cannot be empty!" && return

    while true; do
        choice=$(zenity --list --title="Student Menu" --column="Options" \
            "List Books" "Check Out Book" "Return Book" "Search Books" "Exit" \
            --height=250 --width=300)
        case $choice in
            "List Books") list_books ;;
            "Check Out Book") check_out_book "$student_id" ;;
            "Return Book") return_book "$student_id" ;;
            "Search Books") search_books ;;
            "Exit") break ;;
            *) zenity --error --text="Invalid choice!" ;;
        esac
    done
}

check_out_book() {
    student_id=$1
    book_id=$(zenity --entry --title="Check Out Book" --text="Enter Book ID to check out:")
    [ -z "$book_id" ] && zenity --error --text="Book ID cannot be empty!" && return

    if grep -q "^$book_id," $LIBRARY_FILE; then
        if ! grep -q "^$book_id,.*,.*" $LIBRARY_FILE; then
            sed -i "/^$book_id,/ s/$/,$student_id/" $LIBRARY_FILE
            log_action "Book checked out: ID=$book_id by Student=$student_id"
            zenity --info --text="Book checked out successfully!"
        else
            zenity --warning --text="This book is already checked out!"
        fi
    else
        zenity --error --text="No book found with the given ID!"
    fi
}

return_book() {
    student_id=$1
    book_id=$(zenity --entry --title="Return Book" --text="Enter Book ID to return:")
    [ -z "$book_id" ] && zenity --error --text="Book ID cannot be empty!" && return

    if grep -q "^$book_id,.*,$student_id" $LIBRARY_FILE; then
        sed -i "/^$book_id,/ s/,$student_id//" $LIBRARY_FILE
        log_action "Book returned: ID=$book_id by Student=$student_id"
        zenity --info --text="Book returned successfully!"
    else
        zenity --error --text="No record of this book being checked out by you!"
    fi
}

search_books() {
    keyword=$(zenity --entry --title="Search Books" --text="Enter Title/Author Keyword:")
    [ -z "$keyword" ] && zenity --error --text="Keyword cannot be empty!" && return

    matches=$(grep -i "$keyword" $LIBRARY_FILE | awk -F, '{printf "%-10s %-20s %-20s\n", $1, $2, $3}')
    if [ -z "$matches" ]; then
        zenity --warning --text="No books found matching the keyword."
    else
        echo -e "Book ID   Title                Author\n-----------------------------------------\n$matches" | zenity --text-info --title="Search Results" --width=500 --height=400
    fi
}

# Main Loop
while true; do
    show_main_menu
done
