#!/bin/bash

creds_file=".pdf_creds.txt"
output_pdf="output.pdf"
output_text="extracted_text.txt"
custom_lessons_file="custom_lessons.txt"
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

# Prompt user for the day or set to add custom lessons
echo "Enter the day (mo, di, mi, do, fr) or type 'set' to add custom lessons:"
read day

case $day in
  mo) day="montag";;
  di) day="dienstag";;
  mi) day="mittwoch";;
  do) day="donnerstag";;
  fr) day="freitag";;
  set) add_custom_lesson
       exit 0;;
  *) echo "Invalid day. Please enter mo, di, mi, do, or fr."
     exit 1;;
esac

url="https://bs-korbach.de/images/vertretungsplan/${day}.pdf"

echo "Fetching PDF from $url..."

# Use wget with credentials to download the PDF
wget --user="$username" --password="$password" "$url" -O "$output_pdf"

# Extract text from the PDF using different options
pdftotext -layout -eol unix "$output_pdf" "$output_text"

# Print the extracted text to the console with case-insensitive color for custom lessons
awk -v green_color="$green_color" -v reset_color="$reset_color" 'BEGIN {IGNORECASE=1}
  NR==FNR { custom_lessons[$0]; next }
  {
    for (lesson in custom_lessons) {
      if (index($0, lesson) > 0) {
        print green_color $0 reset_color;
        next;
      }
    }
    print $0;
  }
' "$custom_lessons_file" "$output_text"

# Clean up: remove the downloaded PDF
rm "$output_pdf"

echo "Extracted text saved to $output_text."
