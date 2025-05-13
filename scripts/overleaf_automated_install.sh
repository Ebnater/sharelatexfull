#!/bin/bash

# ==============================================================================
# Bash Skript zur Installation von Overleaf (ShareLaTeX) unter WSL.
# Nutzt das Overleaf Toolkit und Docker. Erstellt optional Desktop- und
# Startmenü-Verknüpfungen unter Windows, die Overleaf über WSL starten.
#
# Voraussetzungen:
# - Läuft unter WSL (Windows Subsystem for Linux)
# - Bash Shell
# - Pakete: whiptail, git, wget, sudo
# - Windows: PowerShell ist verfügbar und im PATH
#
# Führen Sie dieses Skript als regulärer Benutzer (nicht root) aus.
# ==============================================================================

# --- Konfiguration und Konstanten ---

# URLs für Overleaf Image, Manager Skript und Icon
CUSTOM_IMAGE_URL="git.serv.eserver.icu/ewbc/sharelatexfull"
MANAGER_SCRIPT_URL="https://git.serv.eserver.icu/ewbc/sharelatexfull/raw/branch/main/scripts/overleaf_manager_script.sh"
ICON_LOCATION_URL="https://git.serv.eserver.icu/ewbc/sharelatexfull/raw/branch/main/scripts/image.ico"
REPO_URL="https://github.com/overleaf/toolkit.git"

# Installationspfad für das Overleaf Toolkit im WSL Dateisystem
OVERLEAF_INSTALL_PATH="/opt/overleaf-toolkit"
OVERLEAF_CONFIG_FILE="$OVERLEAF_INSTALL_PATH/config/overleaf.rc"
OVERLEAF_BIN_PATH="$OVERLEAF_INSTALL_PATH/bin"
OVERLEAF_MANAGER_SCRIPT_LOCAL="$OVERLEAF_BIN_PATH/overleaf_manager_script.sh"
OVERLEAF_SHORTCUT_PATHS_FILE="$OVERLEAF_BIN_PATH/.shortcut_paths"

# Farben für die Konsolenausgabe
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[0;33m'
BLUE='\e[0;34m'
GRAY='\e[1;30m'
NC='\e[0m' # Keine Farbe

# --- Hilfsfunktionen ---

# Gibt eine Statusnachricht aus
print_status() {
    echo -e "${GREEN}>>> ${1}${NC}"
}

# Gibt eine Fehlernachricht aus und beendet das Skript
print_error() {
    echo -e "${RED}!!! FEHLER: ${1}${NC}" >&2
    exit 1
}

# Gibt eine Warnung aus
print_warning() {
    echo -e "${YELLOW}WARNUNG: ${1}${NC}"
}

# Prüft, ob ein Befehl verfügbar ist
command_exists() {
    command -v "$1" &> /dev/null
}

# Führt einen Befehl mit sudo aus und prüft auf Erfolg
run_sudo_command() {
    local cmd="$@"
    print_status "Führe als root aus: $cmd"
    # Verwenden Sie eval, um die Befehlszeichenfolge korrekt zu interpretieren
    if ! eval "sudo $cmd"; then
        print_error "Fehler bei der Ausführung von: $cmd"
    fi
}

# Lädt eine Datei herunter
download_file() {
    local url="$1"
    local destination="$2"
    print_status "Lade Datei herunter: $url nach $destination"
    echo -e "${GRAY}"
    if ! wget -O "$destination" "$url"; then
        echo -e "${NC}"
        print_error "Fehler beim Herunterladen von $url."
    fi
    echo -e "${NC}"
}

# Führt einen PowerShell-Befehl aus und prüft auf Erfolg
run_powershell_command() {
    local cmd="$1"
    print_status "Führe PowerShell Befehl aus: $cmd"
    echo -e "${GRAY}"
    if ! powershell.exe -Command "$cmd"; then
        echo -e "${NC}"
        print_error "Fehler bei der Ausführung des PowerShell Befehls: $cmd"
    fi
    echo -e "${NC}"
}

# --- Installationsfunktionen ---

# Prüft die benötigten Systemabhängigkeiten
check_dependencies() {
    print_status "Prüfe Abhängigkeiten..."
    local missing_deps=()
    local deps=("whiptail" "git" "wget" "sudo" "apt-get")

    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Die folgenden Abhängigkeiten sind nicht installiert: ${missing_deps[*]}. Bitte installieren Sie diese."
    fi

    # PowerShell Prüfung separat, da es ein Windows-Befehl ist
    if ! command_exists "powershell.exe"; then
         print_error "PowerShell.exe wurde nicht im PATH gefunden. Dieses Skript benötigt PowerShell unter Windows (WSL)."
    fi
    print_status "Alle notwendigen Abhängigkeiten gefunden."
}

# Prüft, ob das Skript als root ausgeführt wird
check_root_user() {
    if [ "$(id -u)" -eq 0 ]; then
        print_error "Bitte führen Sie dieses Skript NICHT als root (mit sudo) aus. Es werden sudo-Berechtigungen bei Bedarf angefordert."
    fi
    print_status "Skript wird als regulärer Benutzer ausgeführt. Gut."
}

# Prüft Docker und bietet Installation an
check_and_install_docker() {
    print_status "Prüfe auf Docker-Installation..."
    if ! command_exists "docker"; then
        print_warning "Docker scheint nicht installiert oder nicht im PATH zu sein."

        # Versuche whiptail nur, wenn ein interaktives Terminal vorhanden ist
        if [ -t 0 ] && [ -t 1 ]; then
            if whiptail --title "Docker Installation" --yesno "Docker ist nicht installiert oder nicht im PATH. Soll es installiert werden?\n(Dies erfordert sudo-Berechtigungen und eine Internetverbindung.)" 12 78; then
                print_status "Beginne Docker-Installation (Ubuntu/Debian-basiert)..."

                # Die Docker-Installationsschritte erfordern root-Berechtigungen.
                # Wir nutzen hier direkt run_sudo_command.

                # Sicherstellen, dass APT aktualisiert ist und notwendige Pakete installiert sind
                run_sudo_command "apt-get update"
                run_sudo_command "apt-get install -y ca-certificates curl gnupg" # gnupg oft für keyrings nötig

                # Docker GPG Schlüssel hinzufügen
                run_sudo_command "install -m 0755 -d /etc/apt/keyrings"
                run_sudo_command "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
                run_sudo_command "chmod a+r /etc/apt/keyrings/docker.gpg"

                # Docker APT Repository hinzufügen
                echo \
                  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
                  run_sudo_command "tee /etc/apt/sources.list.d/docker.list > /dev/null"

                # Docker installieren
                run_sudo_command "apt-get update"
                run_sudo_command "apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"

                # Benutzer zur 'docker'-Gruppe hinzufügen
                # Dies ermöglicht die Ausführung von Docker-Befehlen ohne sudo,
                # erfordert aber eine Neuanmeldung/Neustart der WSL-Instanz.
                local current_user="$USER"
                if id -Gn "$current_user" | grep -q "docker"; then
                    print_status "Benutzer '$current_user' ist bereits Mitglied der 'docker'-Gruppe."
                else
                    print_status "Füge Benutzer '$current_user' zur Gruppe 'docker' hinzu..."
                    run_sudo_command "usermod -aG docker \"$current_user\""
                    print_warning "Benutzer '$current_user' wurde zur Gruppe 'docker' hinzugefügt.\nSie müssen Ihre WSL-Instanz neu starten (z.B. durch Schließen und erneutes Öffnen des Terminals),\ndamit die Gruppenmitgliedschaft wirksam wird und Sie Docker ohne sudo nutzen können."
                fi

                print_status "Docker wurde erfolgreich installiert."
            else
                print_status "Docker-Installation wurde vom Benutzer übersprungen."
            fi
        else
            print_warning "Kein interaktives Terminal erkannt. Docker-Abfrage übersprungen."
            print_warning "Wenn Docker benötigt wird, stellen Sie bitte sicher, dass es manuell installiert ist."
            # Optional: Skript hier beenden, wenn Docker zwingend erforderlich ist
            # exit 1
        fi
    else
        print_status "Docker ist bereits installiert und im PATH gefunden."
    fi
}

# Klont oder aktualisiert das Overleaf Toolkit Repository
clone_overleaf_toolkit() {
    print_status "Verwalte Overleaf Toolkit Repository ($OVERLEAF_INSTALL_PATH)..."

    if [ -d "$OVERLEAF_INSTALL_PATH" ]; then
        if [ -d "$OVERLEAF_INSTALL_PATH/.git" ]; then
            print_status "Repository-Verzeichnis existiert bereits und ist ein Git-Repository. Versuche zu aktualisieren..."
            # Hier könnte man `git pull` hinzufügen, wenn man das Repository aktualisieren möchte,
            # aber das Originalskript löscht und klont neu, wenn es kein Git-Repo ist.
            # Wenn wir immer neu klonen wollen, löschen wir einfach zuerst.
             print_status "Lösche bestehendes Verzeichnis, um neu zu klonen (wie im Originalskript)."
             run_sudo_command "rm -rf \"$OVERLEAF_INSTALL_PATH\""
        else
            print_warning "Verzeichnis $OVERLEAF_INSTALL_PATH existiert, ist aber kein Git-Repository. Es wird gelöscht."
            run_sudo_command "rm -rf \"$OVERLEAF_INSTALL_PATH\""
        fi
    fi

    # Erstelle das Installationsverzeichnis, falls es nicht existiert oder gelöscht wurde
    if [ ! -d "$OVERLEAF_INSTALL_PATH" ]; then
        print_status "Erstelle Installationsverzeichnis: $OVERLEAF_INSTALL_PATH"
        run_sudo_command "mkdir -p \"$OVERLEAF_INSTALL_PATH\""
    fi

    # Klonen des Repositories. Da wir in /opt klonen, benötigen wir sudo.
    print_status "Klone Git-Repository: $REPO_URL nach $OVERLEAF_INSTALL_PATH/."
    echo -e "${GRAY}" # Ausgabe von git clone einfärben
    if ! sudo git clone "$REPO_URL" "$OVERLEAF_INSTALL_PATH/."; then
         echo -e "${NC}"
         print_error "Fehler beim Klonen des Git-Repositories."
    fi
    echo -e "${NC}" # Farben zurücksetzen

    # Das init Skript und andere Binaries ausführbar machen
    print_status "Setze Ausführungsrechte für Toolkit Binaries..."
    run_sudo_command "chmod +x \"$OVERLEAF_INSTALL_PATH\"/*"

    print_status "Overleaf Toolkit erfolgreich geklont/verwaltet."
}

# Initialisiert und konfiguriert Overleaf
configure_overleaf() {
    print_status "Initialisiere Overleaf Toolkit..."
    # Das init-Skript erstellt die Konfigurationsdateien und benötigt sudo
    run_sudo_command "\"$OVERLEAF_BIN_PATH/init\""

    print_status "Passe Konfiguration an: $OVERLEAF_CONFIG_FILE"
    if [ -f "$OVERLEAF_CONFIG_FILE" ]; then
        # Setzt das benutzerdefinierte Docker-Image.
        # Nutzt Anker (&) und (&T) um nur die Zeile mit OVERLEAF_IMAGE_NAME zu ändern.
        # Das &T fügt den gefundenen Match (&) plus den gewünschten Text (T) ein.
        # | dient als Trennzeichen für sed.
        run_sudo_command "sed -i 's|^#\\? *OVERLEAF_IMAGE_NAME=.*|OVERLEAF_IMAGE_NAME=\"$CUSTOM_IMAGE_URL\"|' \"$OVERLEAF_CONFIG_FILE\""
        if [ $? -ne 0 ]; then
             print_error "Fehler beim Anpassen der Konfigurationsdatei."
        fi
        print_status "Konfiguration erfolgreich angepasst (OVERLEAF_IMAGE_NAME gesetzt)."
    else
        print_error "Konfigurationsdatei '$OVERLEAF_CONFIG_FILE' nicht gefunden nach 'init'."
    fi
}

download_manager_script() {
    print_status "Lade Manager-Skript herunter..."
    # Das Skript wird im bin-Verzeichnis gespeichert
    download_file "$MANAGER_SCRIPT_URL" "$OVERLEAF_MANAGER_SCRIPT_LOCAL"
    run_sudo_command "chmod +x \"$OVERLEAF_MANAGER_SCRIPT_LOCAL\""
}

# Erstellt eine Windows Desktop oder Startmenü Verknüpfung über PowerShell
create_wsl_shortcut() {
    local shortcut_file="$1"        # Pfad zur .lnk Datei (Windows Pfad)
    local wsl_command_args="$2"     # Argumente für wsl.exe (z.B. "-e bash -c \"...\"")
    local wsl_working_directory="$3" # Arbeitsverzeichnis für den WSL-Befehl (Linux Pfad)
    local icon_file="$4"            # Pfad zur .ico Datei (Windows Pfad)
    local description="$5"          # Beschreibung für die Verknüpfung (optional)

    print_status "Erstelle Verknüpfung: $shortcut_file"

    # Wichtig: Wir müssen Bash-Variablen in den PowerShell-Befehl einbetten.
    # Dies geschieht durch das Beenden des einfachen Anführungszeichens,
    # Einfügen der Bash-Variable in doppelten Anführungszeichen,
    # und dann Fortsetzen des einfachen Anführungszeichens.
    # Die PowerShell-Variablen (mit $) müssen escaped (\$) oder
    # innerhalb von doppelten Anführungszeichen verwendet werden, wo PowerShell
    # Expansion wünscht (was hier nicht der Fall ist, da wir Bash-Variablen nutzen).
    # Der PowerShell-Befehl selbst wird in einfachen Anführungszeichen übergeben,
    # aber die Bash-Variablen werden außerhalb eingefügt.

    local ps_command="
        \$WshShell = New-Object -ComObject WScript.Shell;
        \$shortcut = \$WshShell.CreateShortcut('$shortcut_file');
        \$shortcut.Arguments = '$wsl_command_args';
        \$shortcut.WorkingDirectory = 'C:\\Windows\\System32'; # Standard für wsl.exe
        \$shortcut.TargetPath = 'C:\\Windows\\System32\\wsl.exe';
        \$shortcut.IconLocation = '$icon_file';
        \$shortcut.Description = '$description';
        \$shortcut.Save();
        "
    # Entferne führende/abschließende Leerzeichen und leere Zeilen
    ps_command=$(echo "$ps_command" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//;/^$/d')

    run_powershell_command "$ps_command"
}

# Fragt nach und erstellt die Desktop-Verknüpfung
ask_and_create_desktop_shortcut() {
    if [ -t 0 ] && [ -t 1 ]; then
        if whiptail --title "Overleaf Installation" --yesno "Soll eine Desktop-Verknüpfung unter Windows erstellt werden?" 10 78; then
            print_status "Bereite Erstellung der Desktop-Verknüpfung vor..."

            # Pfade im Windows-Format ermitteln
            local win_desktop_path
            win_desktop_path=$(run_powershell_command "[Environment]::GetFolderPath('Desktop') | Write-Host")
            # powershell.exe Write-Host gibt saubere Ausgabe ohne CRLF, aber trimmen schadet nicht
            win_desktop_path=$(echo "$win_desktop_path" | sed 's/\r//g; s/^[[:space:]]*//; s/[[:space:]]*$//')
            if [ -z "$win_desktop_path" ]; then
                print_error "Konnte den Windows Desktop Pfad nicht ermitteln."
            fi
            local shortcut_file="${win_desktop_path}\\Overleaf.lnk"

            local win_userprofile_path
            win_userprofile_path=$(run_powershell_command "[Environment]::GetFolderPath('UserProfile') | Write-Host")
             win_userprofile_path=$(echo "$win_userprofile_path" | sed 's/\r//g; s/^[[:space:]]*//; s/[[:space:]]*$//')
            if [ -z "$win_userprofile_path" ]; then
                print_error "Konnte den Windows Benutzerprofil Pfad nicht ermitteln."
            fi
            local win_icon_file="${win_userprofile_path}\\image.ico"

            # Icon herunterladen (direkt nach Windows über PowerShell)
            print_status "Lade Icon für Verknüpfung herunter nach: $win_icon_file"
            run_powershell_command "Invoke-WebRequest -Uri \"$ICON_LOCATION_URL\" -OutFile \"$win_icon_file\""


            # Den WSL-Befehl vorbereiten, der von der Verknüpfung ausgeführt wird.
            # Dieser Befehl wechselt in das Toolkit-Verzeichnis im WSL und führt
            # das Manager-Skript mit sudo aus.
            # Wichtig: Doppelte Anführungszeichen im bash -c String müssen escaped werden (\")
            local wsl_command_args="-e bash -c \"cd \\\"$OVERLEAF_INSTALL_PATH\\\" && sudo ./bin/overleaf_manager_script.sh\""

            # Desktop-Verknüpfung erstellen
            create_wsl_shortcut \
                "$shortcut_file" \
                "$wsl_command_args" \
                "$OVERLEAF_INSTALL_PATH" \
                "$win_icon_file" \
                "Startet/Verwaltet den Overleaf (ShareLaTeX) Server in WSL"

            print_status "Desktop-Verknüpfung erfolgreich erstellt: $shortcut_file"

            # Speichere den Pfad für die Deinstallation/Verwaltung
            echo "export OVERLEAF_SHORTCUT_PATH='$shortcut_file'" >> "$OVERLEAF_SHORTCUT_PATHS_FILE"
            echo "export OVERLEAF_ICON_PATH='$win_icon_file'" >> "$OVERLEAF_SHORTCUT_PATHS_FILE"

            # Fragen nach Startmenü-Verknüpfung direkt danach
            ask_and_create_start_menu_shortcut "$wsl_command_args" "$win_icon_file"

        else
            print_status "Erstellung der Desktop-Verknüpfung wurde übersprungen."
        fi
    else
        print_warning "Kein interaktives Terminal erkannt. Abfrage zur Erstellung der Desktop-Verknüpfung übersprungen."
    fi
}

# Fragt nach und erstellt die Startmenü-Verknüpfung
# Nimmt die bereits erstellten wsl_command_args und den icon_file Pfad entgegen
ask_and_create_start_menu_shortcut() {
    local wsl_command_args="$1"
    local win_icon_file="$2"

     if [ -t 0 ] && [ -t 1 ]; then
        if whiptail --title "Overleaf Installation" --yesno "Soll ein Startmenü-Eintrag unter Windows angelegt werden?" 10 78; then
            print_status "Bereite Erstellung des Startmenü-Eintrags vor..."

            # Pfad im Windows-Format ermitteln
            local win_startmenu_path
            win_startmenu_path=$(run_powershell_command "[Environment]::GetFolderPath('StartMenu') | Write-Host")
            win_startmenu_path=$(echo "$win_startmenu_path" | sed 's/\r//g; s/^[[:space:]]*//; s/[[:space:]]*$//')
             if [ -z "$win_startmenu_path" ]; then
                print_error "Konnte den Windows Startmenü Pfad nicht ermitteln."
            fi
            # Optional: Unterordner hinzufügen
            local shortcut_file="${win_startmenu_path}\\Programs\\Overleaf.lnk" # Ändere "Programs" falls gewünscht

            # Startmenü-Verknüpfung erstellen
            create_wsl_shortcut \
                "$shortcut_file" \
                "$wsl_command_args" \
                "$OVERLEAF_INSTALL_PATH" \
                "$win_icon_file" \
                "Startet/Verwaltet den Overleaf (ShareLaTeX) Server in WSL"

            print_status "Startmenü-Eintrag erfolgreich erstellt: $shortcut_file"

            # Speichere den Pfad für die Deinstallation/Verwaltung
            echo "export OVERLEAF_START_MENU_PATH='$shortcut_file'" >> "$OVERLEAF_SHORTCUT_PATHS_FILE"

        else
            print_status "Erstellung des Startmenü-Eintrags wurde übersprungen."
        fi
     else
        print_warning "Kein interaktives Terminal erkannt. Abfrage zur Erstellung des Startmenü-Eintrags übersprungen."
     fi
}

# --- Hauptausführung des Skripts ---

print_status "Beginne Overleaf (ShareLaTeX) Installation Skript für WSL."

# Zeige Willkommensnachricht
if [ -t 0 ] && [ -t 1 ]; then
     whiptail --title "Overleaf Installation" --msgbox "Dieses Skript installiert Overleaf (ShareLaTeX) auf Ihrem System unter Verwendung von Docker in WSL." 10 78
fi

# Abhängigkeiten prüfen
check_dependencies

# Prüfen, ob Skript als root läuft (sollte nicht)
check_root_user

# Docker prüfen und ggf. installieren
check_and_install_docker

# Git-Repository klonen/verwalten
clone_overleaf_toolkit

# Overleaf initialisieren und konfigurieren
configure_overleaf

# Manager-Skript herunterladen
download_manager_script

# Desktop-Verknüpfung anbieten und erstellen (inkl. Icon und Manager Skript Download)
ask_and_create_desktop_shortcut

# Abschlussnachricht
print_status "Overleaf (ShareLaTeX) Installation abgeschlossen."
print_status "Details zum Starten und Verwalten finden Sie in '$OVERLEAF_BIN_PATH'."

exit 0