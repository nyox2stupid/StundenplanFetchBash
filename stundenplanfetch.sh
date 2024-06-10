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

# Function to check for 'Ausfall' and send notification
check_for_ausfall() {
    local upload_info=$(grep -oP 'Stand Upload:.*$' "$output_text" | awk '{print $3, $5}')
    awk -v pa="$PRINTALL" -v upload="$upload_info" '
      BEGIN {IGNORECASE=1; ausfall_found=0}
      NR==FNR {cust[$0]; next}  # Load custom lessons into array
      /Ausfall/ {
        line = $0;
        gsub(/\*{6}/, "", line);  # Clean up the line
        for (lesson in cust) {
          if (index(line, lesson) > 0) {
            ausfall_found=1;  # Mark Ausfall found
            ausfall_lines = ausfall_lines (ausfall_lines ? "\n" : "") line;  # Collect Ausfall lines
          }
        }
      }
      END {
        if (ausfall_found)
          system("notify-send \"Ausfall\" \"" ausfall_lines "\nUpload: " upload "\"");
        else
          system("notify-send \"Kein Ausfall\" \"\nUpload: " upload "\"");
      }
    ' "$custom_lessons_file" "$output_text"
}

get_current_day() {
    local day_name=$(date +%A)
    case "$day_name" in
        Monday) echo "mo" ;;
        Tuesday) echo "di" ;;
        Wednesday) echo "mi" ;;
        Thursday) echo "do" ;;
        Friday) echo "fr" ;;
        Saturday) echo "mo" ;;  # Assuming Monday's schedule on Saturdays
        Sunday) echo "mo" ;;  # Assuming Monday's schedule on Sundays
    esac
}

# Print extracted text with options
print_text() {    
    local upload_info=$(grep -oP 'Stand Upload:.*$' "$output_text" | awk '{print $3, $5}')
    awk -v gc="$green_color" -v rc="$reset_color" -v pa="$PRINTALL" -v upload="$upload_info" '
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
              print gc line rc "\nUpload:" upload "\n";  # Print colored line if not printing all
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
    local mode="$1"
    local owner="${2:-owner}"

    if [[ $mode == "noti" ]]; then
        # Check if a specific day is given, if not, use current day
        if [[ -n $2 && $2 =~ ^(mo|di|mi|do|fr)$ ]]; then
            day=$(translate_day "$2")
            owner="${3:-owner}"
        else
            day=$(translate_day "$(get_current_day)")
        fi
        custom_lessons_file="${script_dir}/${owner}_lessons.txt"
        handle_pdf "$day"
        check_for_ausfall
        rm "$output_pdf" "$output_text"
    else
        case $mode in
            mo|di|mi|do|fr)
                day=$(translate_day "$mode")
                custom_lessons_file="${script_dir}/${owner}_lessons.txt"
                handle_pdf "$day"
                print_text
                rm "$output_pdf" "$output_text"
                ;;
            set) 
                change_settings
                ;;
            exit) 
                exit 0
                ;;
            *) 
                echo "Invalid input. Please enter 'noti', mo, di, mi, do, fr, 'set', or 'exit'."
                exit 1
                ;;
        esac
    fi
}


translate_day() {
    declare -A days=( ["mo"]="montag" ["di"]="dienstag" ["mi"]="mittwoch" ["do"]="donnerstag" ["fr"]="freitag" )
    echo "${days[$1]}"
}


# Input processing
if [ $# -eq 0 ]; then
    echo "Enter the day (mo, di, mi, do, fr), type 'set' for settings, or 'exit' to quit:"
    read input
    set -- $input
fi

main "$@"