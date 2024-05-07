# StundenplanFetch

`stundenplanfetch.sh` is a Bash script designed to fetch the substitution plan and filter it. It is designed for the BS-Korbach website but it should be universally usable with little adjusments.

## Prerequisites

- `wget` for downloading files.
- `pdftotext` for converting PDF documents to plain text. This tool is typically part of the `poppler-utils` package.
- `awk` for text processing.

## Installation

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/nyox2stupid/StundenplanFetchBash.git
   cd StundenplanFetchBash
   ```

2. **Make the Script Executable:**
   ```bash
   chmod +x stundenplanfetch.sh
   ```

3. **Install Required Packages:**
   - For Debian/Ubuntu:
     ```bash
     sudo apt-get install wget poppler-utils
     ```
   - For Fedora:
     ```bash
     sudo dnf install wget poppler-utils
     ```
   - For Arch Linux:
     ```bash
     sudo pacman -S wget poppler-utils
     ```

## Configuration

### Setting Up Credentials

On the first run, the script will prompt you to enter your username and password, which it will store locally in a hidden file within the script directory. This information is used to authenticate when downloading the PDF.

### Adding Custom Lessons

To highlight custom lessons from the substitution plan:
1. Run the script with the `add` command followed by the lesson identifier.
   ```bash
   ./stundenplanfetch.sh add
   ```
2. Follow the prompts to enter the lesson identifiers (e.g., E2Ph_Pb23).

### Modifying Settings

To change settings such as toggling the display of only highlighted lines:
1. Run the script with the `set` command.
   ```bash
   ./stundenplanfetch.sh set
   ```
2. Follow the prompts to modify the settings.

## Usage

To run the script, simply execute it with the day of the week as an argument:
```bash
./stundenplanfetch.sh mo
```

Supported day abbreviations are:
- `mo` for Monday
- `di` for Tuesday
- `mi` for Wednesday
- `do` for Thursday
- `fr` for Friday

## Setup Alias in .bashrc

To make the script easier to run, you can add an alias in your `.bashrc` file:
1. Open your `.bashrc`:
   ```bash
   nano ~/.bashrc
   ```
2. Add the following alias (modify the path to where your script is located):
   ```bash
   alias stplan='~/path_to_script/stundenplanfetch.sh'
   ```
3. Source your `.bashrc` to apply the changes:
   ```bash
   source ~/.bashrc
   ```

Now, you can run the script using the `stplan` command followed by the day abbreviation:
```bash
stplan fr
```
