#!/bin/bash

creds_file=".pdf_creds.txt"
output_pdf="output.pdf"
output_text="extracted_text.txt"
custom_lessons_file="custom_lessons.txt"
settings_file="settings.txt"

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
if [ $# -eq 1 ]; then
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

    url="https://bs-korbach.de/images/vertretungsplan/${day}.pdf"
    echo "${url}"  # Light blue color for the URL
    
    # Use wget with credentials to download the PDF
    wget --user="$username" --password="$password" "$url" -O "$output_pdf" > /dev/null 2>&1

    # Extract text from the PDF using different options
    pdftotext -layout -eol unix "$output_pdf" "$output_text"

    # Print the extracted text to the console with or without coloring based on settings
    awk -v print_all="$PRINTALL" '
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
              gsub(/\*+$/, "", $0);  # Remove trailing asterisks
              print $0;
            } else {
              colored_lines[FNR]=1;
            }
          }
        }
      }
      {
        if (print_all) {
          next;
        }
      }
      FNR in colored_lines {
        gsub(/\*+$/, "", $0);  # Remove trailing asterisks
        print $0;
      }
    ' "$custom_lessons_file" "$output_text"


    # Clean up: remove the downloaded PDF
    rm "$output_pdf"
    rm extracted_text.txt

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
echo "${url}"  # Light blue color for the URL
# Use wget with credentials to download the PDF
wget --user="$username" --password="$password" "$url" -O "$output_pdf" > /dev/null 2>&1

# Extract text from the PDF using different options
pdftotext -layout -eol unix "$output_pdf" "$output_text"

# Print the extracted text to the console with or without coloring based on settings
awk -v print_all="$PRINTALL" '
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
          print $0;
        } else {
          colored_lines[FNR]=1;
        }
      }
    }
  }
  {
    if (print_all) {
      next;
    }
  }
  FNR in colored_lines {
    print $0;
  }
' "$custom_lessons_file" "$output_text"

# Clean up: remove the downloaded PDF
rm "$output_pdf"
rm extracted_text.txt
