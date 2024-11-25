#!/bin/bash

LIBRARY_FILE="library.txt"

# Ensure the library file exists
if [ ! -f "$LIBRARY_FILE" ]; then
    touch "$LIBRARY_FILE"
fi

show_main_menu() {
    choice=$(zenity --list --title="Library Management System" --column="Options" \
        "Librarian" "Student" "Exit" \
        --height=250 --width=300)
    case $choice in
        "Librarian") librarian_login ;;
        "Student") student_menu ;;
        "Exit") exit 0 ;;
        *) zenity --error --text="Invalid choice!" ;;
    esac
}

librarian_login() {
    username=$(zenity --entry --title="Librarian Login" --text="Enter Username:")
    password=$(zenity --password --title="Librarian Login" --text="Enter Password:")
    if [ "$username" == "mahfuzur" ] && [ "$password" == "5270" ]; then
        zenity --info --text="Login successful!" --title="Login"
        librarian_menu
    else
        zenity --error --text="Login failed!" --title="Error"
    fi
}

librarian_menu() {
    while true; do
        choice=$(zenity --list --title="Librarian Menu" --column="Options" \
            "Add Book" "Delete Book" "List Books" "Logout" \
            --height=250 --width=300)
        case $choice in
            "Add Book") add_book ;;
            "Delete Book") delete_book ;;
            "List Books") list_books ;;
            "Logout") break ;;
            *) zenity --error --text="Invalid choice!" ;;
        esac
    done
}

add_book() {
    book_id=$(zenity --entry --title="Add Book" --text="Enter Book ID:")
    if [ -z "$book_id" ]; then
        zenity --error --text="Book ID cannot be empty!"
        return
    fi
    
    title=$(zenity --entry --title="Add Book" --text="Enter Book Title:")
    if [ -z "$title" ]; then
        zenity --error --text="Book Title cannot be empty!"
        return
    fi
    
    author=$(zenity --entry --title="Add Book" --text="Enter Author Name:")
    if [ -z "$author" ]; then
        zenity --error --text="Author Name cannot be empty!"
        return
    fi

    echo "$book_id,$title,$author" >> $LIBRARY_FILE
    zenity --info --text="Book added successfully!"
}

delete_book() {
    book_id=$(zenity --entry --title="Delete Book" --text="Enter Book ID to delete:")
    if [ -z "$book_id" ]; then
        zenity --error --text="Book ID cannot be empty!"
        return
    fi

    if grep -q "^$book_id," $LIBRARY_FILE; then
        grep -v "^$book_id," $LIBRARY_FILE > temp_file && mv temp_file $LIBRARY_FILE
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

    books=$(awk -F, '{printf "%-10s %-20s %-20s\n", $1, $2, $3}' $LIBRARY_FILE)
    formatted_books="Book ID   Title                Author\n-----------------------------------------\n$books"

    echo -e "$formatted_books" | zenity --text-info --title="Book List" --width=500 --height=400
}

student_menu() {
    student_id=$(zenity --entry --title="Student Menu" --text="Enter your Student ID:")
    if [ -z "$student_id" ]; then
        zenity --error --text="Student ID cannot be empty!"
        return
    fi

    while true; do
        choice=$(zenity --list --title="Student Menu" --column="Options" \
            "List Books" "Check Out Book" "Return Book" "Exit" \
            --height=250 --width=300)
        case $choice in
            "List Books") list_books ;;
            "Check Out Book") check_out_book "$student_id" ;;
            "Return Book") return_book "$student_id" ;;
            "Exit") break ;;
            *) zenity --error --text="Invalid choice!" ;;
        esac
    done
}

check_out_book() {
    student_id=$1
    book_id=$(zenity --entry --title="Check Out Book" --text="Enter Book ID to check out:")
    if [ -z "$book_id" ]; then
        zenity --error --text="Book ID cannot be empty!"
        return
    fi

    if grep -q "^$book_id," $LIBRARY_FILE; then
        if ! grep -q "^$book_id,.*,.*" $LIBRARY_FILE; then
            sed -i "/^$book_id,/ s/$/,$student_id/" $LIBRARY_FILE
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
    if [ -z "$book_id" ]; then
        zenity --error --text="Book ID cannot be empty!"
        return
    fi

    if grep -q "^$book_id,.*,$student_id" $LIBRARY_FILE; then
        sed -i "/^$book_id,/ s/,$student_id//" $LIBRARY_FILE
        zenity --info --text="Book returned successfully!"
    else
        zenity --error --text="No record of this book being checked out by you!"
    fi
}

while true; do
    show_main_menu
done
