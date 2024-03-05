# Stundenplan Fetcher

## Beschreibung

Der Stundenplan Fetcher ist ein Bash-Skript, das entwickelt wurde, um Vertretungspläne von der Website der Beruflichen Schulen Korbach herunterzuladen und den extrahierten Text auf der Konsole anzuzeigen. Das Skript bietet auch die Möglichkeit, benutzerdefinierte Stundenpläne hinzuzufügen und Einstellungen zu ändern.

## Verwendung (Nach dem Klonen des Repos)

1. Führe das Skript aus und gib den gewünschten Tag an, um den Vertretungsplan herunterzuladen und anzuzeigen.

   ```bash
   ./stundenplanfetch.sh mi
   ```

2. Das Skript wird nach deinem Benutzernamen und Passwort fragen. Diese werden für den Download benötigt. Die Anmeldedaten werden in der Datei `.pdf_creds.txt` gespeichert.

3. Füge am Ende deiner `.bashrc`-Datei folgendes hinzu:

   ```bash
   sudo nano[text editor deiner wahl] ~/.bashrc
   ```

   ```bash
   [...]
   # Stundenplan
   alias ausfall="$HOME/pfad/zum/programm/stundenplanfetch.sh"
   ```

## Nur deine Kurse

1. Erstelle die Datei `custom_lessons.txt` im selbigen Ordner und füge deine Kurse hinzu, beispielsweise so:

   ```plaintext
   E2PRIN_Pa23
   E2POWI_Pb23
   E2ETHI_Pa23
   E2G_Pd23
   E2E_Pd23
   E2D_Pd23
   E2M_Pf23
   E2BIO_Pf23
   E2PH_Pb23
   E2TKDV_Pa23
   E2SPO_Pf23
   E2ITEC_Pa23
   ```

2. Stelle ein, dass nur deine Kurse angezeigt werden:

   ```bash
   [nyox2stupid]$ ./stundenplanfetch.sh
   Enter the day (mo, di, mi, do, fr), type 'set' for settings, or 'exit' to quit:
   [nyox2stupid]$ set
   Enter 1 to print all lines, or 0 to print only colored lines:
   [nyox2stupid]$ 0
   ```

## Hinweis

Die extrahierten Textdateien (`output.pdf` und `extracted_text.txt`) werden nach der Anzeige gelöscht.
