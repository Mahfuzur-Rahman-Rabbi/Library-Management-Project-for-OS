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
    echo "========== Welcome to the Library Management System =========="
    echo "1. Librarian"
    echo "2. Student"
    echo "3. Exit"
    echo "=============================================================="
    read -p "Enter your choice: " choice
    case $choice in
        1) librarian_login ;;
        2) student_menu ;;
        3) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid choice! Please try again."; show_main_menu ;;
    esac
}

librarian_login() {
    read -p "Enter Username: " username
    read -sp "Enter Password: " password
    echo

    if grep -q "^$username,$password" $LIBRARIANS_FILE; then
        echo "Login successful!"
        log_action "Librarian '$username' logged in."
        librarian_menu
    else
        echo "Login failed! Invalid credentials."
    fi
}

librarian_menu() {
    while true; do
        echo "========== Librarian Menu =========="
        echo "1. Add Book"
        echo "2. Edit Book"
        echo "3. Delete Book"
        echo "4. List Books"
        echo "5. Logout"
        echo "===================================="
        read -p "Enter your choice: " choice
        case $choice in
            1) add_book ;;
            2) edit_book ;;
            3) delete_book ;;
            4) list_books ;;
            5) break ;;
            *) echo "Invalid choice! Please try again." ;;
        esac
    done
}

add_book() {
    read -p "Enter Book ID: " book_id
    [ -z "$book_id" ] && echo "Book ID cannot be empty!" && return

    read -p "Enter Book Title: " title
    [ -z "$title" ] && echo "Book Title cannot be empty!" && return

    read -p "Enter Author Name: " author
    [ -z "$author" ] && echo "Author Name cannot be empty!" && return

    echo "$book_id,$title,$author" >> $LIBRARY_FILE
    log_action "Book added: ID=$book_id, Title=$title, Author=$author"
    echo "Book added successfully!"
}

edit_book() {
    read -p "Enter Book ID to edit: " book_id
    if grep -q "^$book_id," $LIBRARY_FILE; then
        read -p "Enter new Title: " new_title
        read -p "Enter new Author: " new_author
        sed -i "/^$book_id,/ s/.*/$book_id,$new_title,$new_author/" $LIBRARY_FILE
        log_action "Book edited: ID=$book_id, New Title=$new_title, New Author=$new_author"
        echo "Book details updated successfully!"
    else
        echo "Book ID not found!"
    fi
}

delete_book() {
    read -p "Enter Book ID to delete: " book_id
    [ -z "$book_id" ] && echo "Book ID cannot be empty!" && return

    if grep -q "^$book_id," $LIBRARY_FILE; then
        grep -v "^$book_id," $LIBRARY_FILE > temp_file && mv temp_file $LIBRARY_FILE
        log_action "Book deleted: ID=$book_id"
        echo "Book deleted successfully!"
    else
        echo "No book found with the given ID!"
    fi
}

list_books() {
    if [ ! -s $LIBRARY_FILE ]; then
        echo "No books available in the library!"
        return
    fi

    printf "Book ID   Title                Author              Status\n"
    printf "---------------------------------------------------------\n"
    awk -F, '{printf "%-10s %-20s %-20s %-15s\n", $1, $2, $3, ($4 ? "Checked Out" : "Available")}' $LIBRARY_FILE
}

student_menu() {
    read -p "Enter your Student ID: " student_id
    [ -z "$student_id" ] && echo "Student ID cannot be empty!" && return

    while true; do
        echo "========== Student Menu =========="
        echo "1. List Books"
        echo "2. Check Out Book"
        echo "3. Return Book"
        echo "4. Search Books"
        echo "5. Exit"
        echo "=================================="
        read -p "Enter your choice: " choice
        case $choice in
            1) list_books ;;
            2) check_out_book "$student_id" ;;
            3) return_book "$student_id" ;;
            4) search_books ;;
            5) break ;;
            *) echo "Invalid choice! Please try again." ;;
        esac
    done
}

check_out_book() {
    student_id=$1
    read -p "Enter Book ID to check out: " book_id
    [ -z "$book_id" ] && echo "Book ID cannot be empty!" && return

    if grep -q "^$book_id," $LIBRARY_FILE; then
        if ! grep -q "^$book_id,.*,.*" $LIBRARY_FILE; then
            sed -i "/^$book_id,/ s/$/,$student_id/" $LIBRARY_FILE
            log_action "Book checked out: ID=$book_id by Student=$student_id"
            echo "Book checked out successfully!"
        else
            echo "This book is already checked out!"
        fi
    else
        echo "No book found with the given ID!"
    fi
}

return_book() {
    student_id=$1
    read -p "Enter Book ID to return: " book_id
    [ -z "$book_id" ] && echo "Book ID cannot be empty!" && return

    if grep -q "^$book_id,.*,$student_id" $LIBRARY_FILE; then
        sed -i "/^$book_id,/ s/,$student_id//" $LIBRARY_FILE
        log_action "Book returned: ID=$book_id by Student=$student_id"
        echo "Book returned successfully!"
    else
        echo "No record of this book being checked out by you!"
    fi
}

search_books() {
    read -p "Enter Title/Author Keyword: " keyword
    [ -z "$keyword" ] && echo "Keyword cannot be empty!" && return

    matches=$(grep -i "$keyword" $LIBRARY_FILE | awk -F, '{printf "%-10s %-20s %-20s\n", $1, $2, $3}')
    if [ -z "$matches" ]; then
        echo "No books found matching the keyword."
    else
        printf "Book ID   Title                Author\n"
        printf "-----------------------------------------\n"
        echo "$matches"
    fi
}

# Main Loop
while true; do
    show_main_menu
done
