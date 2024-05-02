#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

creds_file="${script_dir}/.pdf_creds.txt"
output_pdf="${script_dir}/output.pdf"
output_text="${script_dir}/extracted_text.txt"
settings_file="${script_dir}/settings.txt"
green_color='\033[0;32m'  # ANSI escape code for green
reset_color='\033[0m'     # ANSI escape code to reset color

# Function to prompt user for credentials
get_credentials() {
    echo "Enter your username:"
    read username
    echo "Enter your password:"
    read -s password
    echo "$username:$password" > "$creds_file"
}

# Function to add custom lessons
add_custom_lesson() {
    echo "Enter the custom lesson (e.g., E2Ph_Pb23):"
    read custom_lesson
    echo "$custom_lesson" >> "$custom_lessons_file"
    echo "Custom lesson added: $custom_lesson"
}

# Function to change settings
change_settings() {
    echo "Enter 1 to print all lines, or 0 to print only colored lines:"
    read print_all_setting
    echo "PRINTALL=$print_all_setting" > "$settings_file"
    echo "Settings updated."
}

# Check and load credentials
check_credentials() {
    if [ ! -e "$creds_file" ] || [ ! -s "$creds_file" ]; then
        echo "No valid credentials found. Creating new ones..."
        get_credentials
    fi
    IFS=':' read -r username password < "$creds_file"
}

# Download PDF and extract text
handle_pdf() {
    local url="https://bs-korbach.de/images/vertretungsplan/${1}.pdf"
    echo -e "\n\e[1;34m$url\e[0m"
    wget --user="$username" --password="$password" "$url" -O "$output_pdf" > /dev/null 2>&1
    pdftotext -layout -eol unix "$output_pdf" "$output_text"
    if [ ! -s "$output_text" ]; then
        echo "No text extracted from the PDF. Exiting."
        exit 0
    fi
}

# Print extracted text with options
print_text() {
    awk -v gc="$green_color" -v rc="$reset_color" -v pa="$PRINTALL" '
      BEGIN {IGNORECASE=1}
      NR==FNR {cust[$0]; next}  # Load custom lessons into array
      {
        print_line = 0;
        line = $0;
        gsub(/\*{6}/, "", line);  # Clean up the line once

        for (lesson in cust) {
          if (index(line, lesson) > 0) {
            print_line = 1;  # Mark line for printing
            if (!pa) {
              print gc line rc;  # Print colored line if not printing all
              next;
            }
          }
        }
        if (pa && print_line) {
          print gc line rc;  # Print colored line if printing all
        } else if (pa) {
          print line;  # Print normal line if printing all
        }
      }
    ' "$custom_lessons_file" "$output_text"
}


# Main function
main() {
    check_credentials
    [ ! -e "$settings_file" ] && echo "PRINTALL=1" > "$settings_file"
    source "$settings_file"

    local day=""
    case $1 in
        mo) day="montag";;
        di) day="dienstag";;
        mi) day="mittwoch";;
        do) day="donnerstag";;
        fr) day="freitag";;
        set) change_settings; return;;
        exit) exit 0;;
        *) echo "Invalid input. Please enter mo, di, mi, do, fr, 'set', or 'exit'."; exit 1;;
    esac

    custom_lessons_file="${script_dir}/${2:-owner}_lessons.txt"
    handle_pdf "$day"
    print_text
    echo "$(grep -oP 'Stand Upload:.*$' "$output_text")"
    echo -e "\nExtracted text saved to $output_text"
    rm "$output_pdf" "$output_text"
}

# Input processing
if [ $# -eq 0 ]; then
    echo "Enter the day (mo, di, mi, do, fr), type 'set' for settings, or 'exit' to quit:"
    read input
    set -- $input
fi

main "$@"