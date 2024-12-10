#!/bin/bash

# Set dark theme for Zenity dialogs
export GTK_THEME=Adwaita:dark

LIBRARY_FILE="library.txt"
LIBRARIANS_FILE="librarians.txt"
STUDENTS_FILE="students.txt"
BORROWED_BOOKS_FILE="borrowed_books.txt"
LOG_FILE="library.log"
SECRET_CODE="diu12345"

# Ensure necessary files exist
for file in $LIBRARY_FILE $LIBRARIANS_FILE $STUDENTS_FILE $BORROWED_BOOKS_FILE $LOG_FILE; do
    [ ! -f "$file" ] && touch "$file"
done

log_action() {
    echo "$(date): $1" >> $LOG_FILE
}

show_main_menu() {
    choice=$(zenity --list --title="Library Management System" --column="Options" \
        "Register Librarian" "Login Librarian" "Register Student" "Login Student" "Exit" \
        --height=300 --width=400)
    case $choice in
        "Register Librarian") register_librarian ;;
        "Login Librarian") librarian_login ;;
        "Register Student") register_student ;;
        "Login Student") student_login ;;
        "Exit") 
            zenity --info --title="Goodbye!" --text="Thank you for using the Library Management System. Goodbye!" --width=300
            exit 0 ;;
        *) zenity --error --text="Invalid choice!" ;;
    esac
}

register_librarian() {
    secret=$(zenity --entry --title="Admin Secret Code" --text="Enter Admin Secret Code:")
    if [ "$secret" != "$SECRET_CODE" ]; then
        zenity --error --text="Incorrect Secret Code! Registration denied."
        return
    fi

    username=$(zenity --entry --title="Register Librarian" --text="Enter Username:")
    password=$(zenity --password --title="Register Librarian" --text="Enter Password:")
    if [ -z "$username" ] || [ -z "$password" ]; then
        zenity --error --text="Username and password cannot be empty!"
        return
    fi

    echo "$username,$password" >> $LIBRARIANS_FILE
    zenity --info --text="Registration successful! You can now log in as a Librarian."
}

register_student() {
    student_name=$(zenity --entry --title="Register Student" --text="Enter your Name:")
    student_id=$(zenity --entry --title="Register Student" --text="Enter your Student ID:")
    if [ -z "$student_name" ] || [ -z "$student_id" ]; then
        zenity --error --text="Name and Student ID cannot be empty!"
        return
    fi

    echo "$student_id,$student_name" >> $STUDENTS_FILE
    zenity --info --text="Registration successful! You can now log in as a Student."
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

student_login() {
    student_id=$(zenity --entry --title="Student Login" --text="Enter your Student ID:")

    if grep -q "^$student_id," $STUDENTS_FILE; then
        student_name=$(grep "^$student_id," $STUDENTS_FILE | cut -d, -f2)
        zenity --info --text="Welcome, $student_name!" --title="Student Login"
        log_action "Student '$student_name' (ID: $student_id) logged in."
        student_menu "$student_name" "$student_id"
    else
        zenity --error --text="Login failed! Invalid Student ID."
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

student_menu() {
    local student_name="$1"
    local student_id="$2"

    while true; do
        choice=$(zenity --list --title="Student Menu" --column="Options" \
            "List Books" "Check Out Book" "Return Book" "Logout" \
            --height=250 --width=300)
        case $choice in
            "List Books") list_books ;;
            "Check Out Book") check_out_book "$student_name" "$student_id" ;;
            "Return Book") return_book "$student_id" ;;
            "Logout") break ;;
            *) zenity --error --text="Invalid choice!" ;;
        esac
    done
}

add_book() {
    category=$(zenity --list --title="Select Category" --column="Categories" \
        "Science Fiction" "Mystery" "Thriller" "Romance" "Historical Fiction" "Non-Fiction" \
        --height=400 --width=300)

    [ -z "$category" ] && zenity --error --text="Category cannot be empty!" && return

    book_id=$(zenity --entry --title="Add Book" --text="Enter Book ID:")
    [ -z "$book_id" ] && zenity --error --text="Book ID cannot be empty!" && return

    title=$(zenity --entry --title="Add Book" --text="Enter Book Title:")
    [ -z "$title" ] && zenity --error --text="Book Title cannot be empty!" && return

    author=$(zenity --entry --title="Add Book" --text="Enter Author Name:")
    [ -z "$author" ] && zenity --error --text="Author Name cannot be empty!" && return

    echo "$book_id,$title,$author,$category" >> $LIBRARY_FILE
    log_action "Book added: ID=$book_id, Title=$title, Author=$author, Category=$category"
    zenity --info --text="Book added successfully!"
}

edit_book() {
    book_id=$(zenity --entry --title="Edit Book" --text="Enter Book ID to edit:")
    if grep -q "^$book_id," $LIBRARY_FILE; then
        title=$(zenity --entry --title="Edit Book" --text="Enter new Title (leave empty to keep unchanged):")
        author=$(zenity --entry --title="Edit Book" --text="Enter new Author (leave empty to keep unchanged):")
        category=$(zenity --list --title="Edit Book - Category" --column="Categories" \
            "Science Fiction" "Mystery" "Thriller" "Romance" "Historical Fiction" "Non-Fiction" --height=400 --width=300)

        awk -F, -v id="$book_id" -v title="$title" -v author="$author" -v category="$category" '
        BEGIN { OFS = FS }
        $1 == id {
            if (title != "") $2 = title
            if (author != "") $3 = author
            if (category != "") $4 = category
        }
        { print }
        ' $LIBRARY_FILE > temp_file && mv temp_file $LIBRARY_FILE

        log_action "Book edited: ID=$book_id"
        zenity --info --text="Book details updated successfully!"
    else
        zenity --error --text="Book ID not found!"
    fi
}

delete_book() {
    book_id=$(zenity --entry --title="Delete Book" --text="Enter Book ID to delete:")
    if grep -q "^$book_id," $LIBRARY_FILE; then
        grep -v "^$book_id," $LIBRARY_FILE > temp_file && mv temp_file $LIBRARY_FILE
        log_action "Book deleted: ID=$book_id"
        zenity --info --text="Book deleted successfully!"
    else
        zenity --error --text="Book ID not found!"
    fi
}


check_out_book() {
    local student_name="$1"
    local student_id="$2"

    book_id=$(zenity --entry --title="Check Out Book" --text="Enter Book ID to check out:")
    if grep -q "^$book_id," $LIBRARY_FILE; then
        if grep -q "^$book_id,$student_id," $BORROWED_BOOKS_FILE; then
            zenity --error --text="You already checked out this book!"
        else
            echo "$book_id,$student_id,$student_name" >> $BORROWED_BOOKS_FILE
            log_action "Book checked out: ID=$book_id by Student ID=$student_id"
            zenity --info --text="Book checked out successfully!"
        fi
    else
        zenity --error --text="Book ID not found!"
    fi
}

return_book() {
    local student_id="$1"

    book_id=$(zenity --entry --title="Return Book" --text="Enter Book ID to return:")
    if grep -q "^$book_id,$student_id," $BORROWED_BOOKS_FILE; then
        grep -v "^$book_id,$student_id," $BORROWED_BOOKS_FILE > temp_file && mv temp_file $BORROWED_BOOKS_FILE
        log_action "Book returned: ID=$book_id by Student ID=$student_id"
        zenity --info --text="Book returned successfully!"
    else
        zenity --error --text="You have not borrowed this book!"
    fi
}

list_books() {
    if [ ! -s $LIBRARY_FILE ]; then
        zenity --info --text="No books available in the library!"
        return
    fi

    books=$(awk -F, '{printf "%-10s %-20s %-20s %-20s\n", $1, $2, $3, $4}' $LIBRARY_FILE)
    formatted_books="Book ID   Title                Author              Category\n---------------------------------------------------------------------\n$books"
    echo -e "$formatted_books" | zenity --text-info --title="Book List" --width=500 --height=400
}

# Main Loop
while true; do
    show_main_menu
done




