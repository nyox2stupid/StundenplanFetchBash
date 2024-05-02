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

# Check if credentials file exists
if [ ! -e "$creds_file" ]; then
    echo "No stored credentials found. Creating a new one..."
    get_credentials
    echo "Credentials stored."
else
    # Read stored credentials
    credentials=$(cat "$creds_file")

    # Check if the file is not empty
    if [ -z "$credentials" ]; then
        echo "Invalid or empty credentials file. Please re-enter your credentials."
        get_credentials
        echo "Credentials stored."
    else
        # Split credentials into username and password
        IFS=':' read -r username password <<< "$credentials"
    fi
fi

# Check if settings file exists
if [ ! -e "$settings_file" ]; then
    echo "No settings found. Creating a new one..."
    echo "PRINTALL=1" > "$settings_file"
    echo "Settings created."
fi

# Read the settings
source "$settings_file"

# Check if a day is provided as a command-line argument
if [ $# -eq 2 ]; then
    # Additional parameter provided, use it for kurs list file
    custom_lessons_file="${script_dir}/${2}_lessons.txt"
fi

if [ $# -eq 1 ] || [ $# -eq 2 ]; then
    case $1 in
      mo) day="montag";;
      di) day="dienstag";;
      mi) day="mittwoch";;
      do) day="donnerstag";;
      fr) day="freitag";;
      set) change_settings
           exit 0;;
      exit) exit 0;;
      *) echo "Invalid input. Please enter mo, di, mi, do, fr, 'set', or 'exit'."
         exit 1;;
    esac

    # Set default custom lessons file name as owner_lessons.txt if no specific name is provided
    if [ $# -eq 1 ]; then
        custom_lessons_file="${script_dir}/owner_lessons.txt"
    elif [ $# -eq 2 ]; then
        # If a second parameter is provided, use it to name the lessons file
        custom_lessons_file="${script_dir}/${2}_lessons.txt"
    fi

    url="https://bs-korbach.de/images/vertretungsplan/${day}.pdf"
    echo -e "\n\e[1;34m$url\e[0m"  # Light blue color for the URL
    
    # Use wget with credentials to download the PDF
    wget --user="$username" --password="$password" "$url" -O "$output_pdf" > /dev/null 2>&1

    # Extract text from the PDF using different options
    pdftotext -layout -eol unix "$output_pdf" "$output_text"

    # Check if the extracted text file is empty
    if [ ! -s "$output_text" ]; then
        echo "No text extracted from the PDF. Exiting."
        rm "$output_pdf"  # Clean up: remove the downloaded PDF
        exit 0
    fi

    # Print the extracted text to the console with or without coloring based on settings
    awk -v green_color="$green_color" -v reset_color="$reset_color" -v print_all="$PRINTALL" '
      BEGIN {
        IGNORECASE = 1;
      }
      NR==FNR {
        custom_lessons[$0];
        next;
      }
      {
        for (lesson in custom_lessons) {
          if (index($0, lesson) > 0) {
            if (print_all) {
              gsub(/\*{6}/, "", $0);  # Remove all occurrences of ******
              print green_color $0 reset_color;
            } else {
              colored_lines[FNR]=1;
            }
          }
        }
      }
      {
        if (print_all) {
          gsub(/\*{6}/, "", $0);  # Remove all occurrences of ******
          next;
        }
      }
      FNR in colored_lines {
        gsub(/\*{6}/, "", $0);  # Remove all occurrences of ******
        print green_color $0 reset_color;
      }
    ' "$custom_lessons_file" "$output_text"

    # Extract and print "Stand Upload" information
    stand_upload_info=$(grep -oP 'Stand Upload:.*$' "$output_text")
    echo "$stand_upload_info"
    echo -e "\n"
  
    # Clean up: remove the downloaded PDF and text file
    rm "$output_pdf"
    rm "$output_text"

    exit 0
fi

# Prompt user for the day or set to add custom lessons
echo "Enter the day (mo, di, mi, do, fr), type 'set' for settings, or 'exit' to quit:"
read input

case $input in
  mo) day="montag";;
  di) day="dienstag";;
  mi) day="mittwoch";;
  do) day="donnerstag";;
  fr) day="freitag";;
  set) change_settings
       exit 0;;
  exit) exit 0;;
  *) echo "Invalid input. Please enter mo, di, mi, do, fr, 'set', or 'exit'."
     exit 1;;
esac

url="https://bs-korbach.de/images/vertretungsplan/${day}.pdf"
echo -e "\n\e[1;34m$url\e[0m"  # Light blue color for the URL
# Use wget with credentials to download the PDF
wget --user="$username" --password="$password" "$url" -O "$output_pdf" > /dev/null 2>&1

# Extract text from the PDF using different options
pdftotext -layout -eol unix "$output_pdf" "$output_text"

# Check if the extracted text file is empty
if [ ! -s "$output_text" ]; then
    echo "No text extracted from the PDF. Exiting."
    rm "$output_pdf"  # Clean up: remove the downloaded PDF
    exit 0
fi

# Print the extracted text to the console with or without coloring based on settings
awk -v green_color="$green_color" -v reset_color="$reset_color" -v print_all="$PRINTALL" '
  BEGIN {
    IGNORECASE = 1;
  }
  NR==FNR {
    custom_lessons[$0];
    next;
  }
  {
    for (lesson in custom_lessons) {
      if (index($0, lesson) > 0) {
        if (print_all) {
          gsub(/\*{6}/, "", $0);  # Remove all occurrences of ******
          print green_color $0 reset_color;
        } else {
          colored_lines[FNR]=1;
        }
      }
    }
  }
  {
    if (print_all) {
      gsub(/\*{6}/, "", $0);  # Remove all occurrences of ******
      next;
    }
  }
  FNR in colored_lines {
    gsub(/\*{6}/, "", $0);  # Remove all occurrences of ******
    print green_color $0 reset_color;
  }
' "$custom_lessons_file" "$output_text"


# Extract and print "Stand Upload" information
stand_upload_info=$(grep -oP 'Stand Upload:.*$' "$output_text")
echo "$stand_upload_info"

# Clean up: remove the downloaded PDF and text file
rm "$output_pdf"
rm "$output_text"

echo "Extracted text saved to $output_text"
