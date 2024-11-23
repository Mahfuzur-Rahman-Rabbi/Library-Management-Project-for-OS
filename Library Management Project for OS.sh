#!/bin/bash

LIBRARY_FILE="library.txt"

# Ensure the library file exists
if [ ! -f "$LIBRARY_FILE" ]; then
    touch "$LIBRARY_FILE"
fi

show_main_menu() {
    clear
    echo "----- W E L C O M E -----"
    echo "Library Management System"
    echo ""
    echo "1. Librarian"
    echo "2. Student"
    echo "3. Exit"
    echo ""
    echo -n "Enter your choice: "
}

librarian_login() {
    clear
    echo "Enter username & password to continue... "
    echo ""
    echo -n "Enter username: "
    read username
    echo -n "Enter password: "
    read -s password
    echo ""
    if [ "$username" == "mahfuzur" ] && [ "$password" == "5270" ]; then
        echo ""
        echo "Login successful..."
        sleep 2
        clear
        librarian_menu
    else
        clear
        echo ""
        echo "Login failed..."
        sleep 3
    fi
}

librarian_menu() {
    while true; do
        echo "----------------"
        echo "Hi! Librarian..."
        echo ""
        echo "Librarian's Menu"
        echo ""
        echo "1. Add Book"
        echo "2. Delete Book"
        echo "3. List Books"
        echo "4. Logout"
        echo ""
        echo -n "Enter your choice: "
        read choice
        case $choice in
            1) add_book ;;
            2) delete_book ;;
            3) list_books ;;
            4) return ;;
            *) echo "Invalid choice. Please choose again." ;;
        esac
    done
}

add_book() {
    clear
    echo "-----Add Book-----"
    echo ""
    echo -n "Enter book ID: "
    read book_id
    echo -n "Enter book title: "
    read title
    echo -n "Enter author name: "
    read author
    echo "$book_id,$title,$author" >> $LIBRARY_FILE
    echo ""
    echo "Book added successfully."
    sleep 2
    clear
}

delete_book() {
    clear
    echo "--------Delete Book--------"
    echo ""
    echo -n "Enter book ID to delete: "
    read book_id
    if grep -q "^$book_id," $LIBRARY_FILE; then
        grep -v "^$book_id," $LIBRARY_FILE > temp_file && mv temp_file $LIBRARY_FILE
        echo ""
        echo "Book deleted successfully."
    else
        echo ""
        echo "No such book exists."
    fi
    sleep 2
    clear
}

list_books() {
    clear
    echo "-----Book List-----"
    echo ""
    echo "Listing all books:"
    echo ""
    echo "Book_ID	Title		Author"
    echo "-------	-----		------"
    while IFS= read -r line
    do
        IFS=',' read -r book_id title author <<< "$line"
        echo "$book_id	$title		$author"
    done < "$LIBRARY_FILE"
    echo ""
}

student_menu() {
    clear
    echo "Enter your student id to continue... "
    echo ""
    echo -n "Enter student ID: "
    read student_id
    echo ""
    sleep 1
    clear
    while true; do
        echo "Welcome to Student Menu"
        echo ""
        echo "1. List Books"
        echo "2. Check Out Book"
        echo "3. Return Book"
        echo "4. Exit"
        echo ""
        echo -n "Enter your choice: "
        read choice
        case $choice in
            1) list_books ;;
            2) check_out_book $student_id ;;
            3) return_book $student_id ;;
            4) return ;;
            *) echo "Invalid choice. Please choose again." ;;
        esac
    done
}

check_out_book() {
    clear
    echo "-----Check Out Book-----"
    echo ""
    student_id=$1
    echo -n "Enter book ID to check out: "
    read book_id
    echo ""
    if grep -q "^$book_id," $LIBRARY_FILE; then
        if ! grep -q "^$book_id,.*,.*" $LIBRARY_FILE; then
            sed -i "/^$book_id,/ s/$/,$student_id/" $LIBRARY_FILE
            echo "Book checked out successfully."
        else
            echo "This book is already checked out."
        fi
    else
        echo "Book not available."
    fi
    sleep 2
    clear
}

return_book() {
	clear
    echo "-----Return Book-----"
    echo ""
    student_id=$1
    echo -n "Enter book ID to return: "
    read book_id
    echo ""
    if grep -q "^$book_id,.*,$student_id" $LIBRARY_FILE; then
        sed -i "/^$book_id,/ s/,$student_id//" $LIBRARY_FILE
        echo "Book returned successfully."
    else
        echo "No record of this book being checked out by you."
    fi
    sleep 1
    clear
}

while true
do
    show_main_menu
    read choice
    case $choice in
        1) librarian_login ;;
        2) student_menu ;;
        3) echo "Exiting program."; exit 0 ;;
        *) echo "Invalid choice. Please choose again." ;;
    esac
    echo
done