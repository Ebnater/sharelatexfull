#!/bin/bash

CUSTOM_IMAGE_URL=git.serv.eserver.icu/ewbc/sharelatexfull
MANAGER_SCRIPT_URL=https://git.serv.eserver.icu/ewbc/sharelatexfull/raw/branch/main/scripts/overleaf_manager_script.sh
ICON_LOCATION_URL=https://git.serv.eserver.icu/ewbc/sharelatexfull/raw/branch/main/scripts/image.ico

# Colors
RED='\033[0;31m'
GRAY='\033[1;30m'
NC='\033[0m'

whiptail --title "Overleaf Installation" --msgbox "Dieses Skript installiert Overleaf auf Ihrem System." 8 78
# Überprüfen, ob Docker installiert ist
if ! type docker &> /dev/null; then
    echo "Docker scheint nicht im PATH gefunden zu werden."
    # Versuche whiptail nur, wenn ein Terminal vorhanden ist
    if [ -t 0 ] && [ -t 1 ]; then
        if whiptail --title "Docker Installation" --yesno "Docker ist nicht installiert oder nicht im PATH. Soll es installiert werden?" 10 78; then
            echo "Installiere Docker..."
            echo -e "${GRAY}" # -e für die Interpretation von Escape-Sequenzen
            # Sicherstellen, dass sudo verfügbar ist oder das Skript als root läuft
            if command -v sudo &> /dev/null; then
                SUDO="sudo"
            elif [ "$(id -u)" -eq 0 ]; then
                SUDO="" # Bereits root, kein sudo nötig
            else
                echo "Fehler: sudo ist nicht verfügbar und das Skript läuft nicht als root. Installation abgebrochen."
                exit 1
            fi

            # Docker-Installation (Ubuntu/Debian basiert)
            $SUDO apt-get update
            $SUDO apt-get install -y ca-certificates curl
            $SUDO install -m 0755 -d /etc/apt/keyrings
            $SUDO curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
            $SUDO chmod a+r /etc/apt/keyrings/docker.asc
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
              $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
              $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
            $SUDO apt-get update
            # Fehlerbehandlung für apt-get install hinzufügen
            if $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                echo -e "${NC}" # -e für die Interpretation von Escape-Sequenzen
                echo "Docker wurde erfolgreich installiert."
                # Fügen Sie den aktuellen Benutzer zur Docker-Gruppe hinzu (optional, erfordert Neuanmeldung)
                if [ -n "$SUDO" ] && [ -n "$USER" ]; then
                   $SUDO usermod -aG docker "$USER"
                   echo "Der Benutzer $USER wurde zur Gruppe 'docker' hinzugefügt. Möglicherweise ist eine Neuanmeldung erforderlich."
                fi
            else
                echo -e "${RED}" # -e für die Interpretation von Escape-Sequenzen
                echo "Fehler bei der Docker-Installation."
                exit 1
            fi
        else
            echo "Docker-Installation übersprungen."
        fi
    else
      echo "Kein interaktives Terminal erkannt. Whiptail-Abfrage übersprungen."
      echo "Wenn Docker installiert werden soll, führen Sie das Installationsskript bitte direkt in einem Terminal aus."
      # Hier könnten Sie entscheiden, ob Sie die Installation trotzdem versuchen wollen (ohne Nachfrage)
      # oder das Skript beenden.
      # exit 1 # Beenden, wenn keine Interaktion möglich ist und Docker fehlt.
    fi
else
    echo "Docker ist bereits installiert und im PATH gefunden."
fi

# Git-Repository klonen
REPO_URL="https://github.com/overleaf/toolkit.git"
LOCAL_PATH=$(pwd)
LOCAL_PATH="$LOCAL_PATH/overleaf-toolkit"
if [ ! -d "$LOCAL_PATH" ]; then
    echo "Klonen des Git-Repositories..."
    echo "${GRAY}"
    git clone "$REPO_URL" "$LOCAL_PATH"
    echo "${NC}"
else
    echo "Das Repository ist bereits geklont."
fi

EXEC_BIN_PATH="$LOCAL_PATH/bin"



# Initialisiere Konfiguration
$EXEC_BIN_PATH/init

# Konfigurationsänderungen vornehmen
CONFIG_FILE_PATH="$LOCAL_PATH/config/overleaf.rc"
if [ -f "$CONFIG_FILE_PATH" ]; then
    echo "Ändern der Konfiguration..."
    # Beispiel für eine Konfigurationsänderung
    sed -i "s|# OVERLEAF_IMAGE_NAME=sharelatex/sharelatex|OVERLEAF_IMAGE_NAME=$CUSTOM_IMAGE_URL|" "$CONFIG_FILE_PATH" 
else
    echo "Konfigurationsdatei nicht gefunden."
fi

if whiptail --title "Overleaf Installation" --yesno "Soll eine Desktop-Verknüpfung erstellt werden?" 8 78; then
    # Managerskript herunterladen
    echo "Lade den Manager-Skript herunter"
    echo "${GRAY}"
    wget -O "$EXEC_BIN_PATH/overleaf_manager_script.sh" "$MANAGER_SCRIPT_URL"
    chmod +x "$EXEC_BIN_PATH/overleaf_manager_script.sh"
    echo "${NC}"

    # Finde Desktop Pfad
    SHORTCUT_PATH=$(powershell.exe -Command "[Environment]::GetFolderPath('Desktop')")
    SHORTCUT_PATH=$(echo "$SHORTCUT_PATH" | sed 's/\r//g')
    SHORTCUT_PATH=$SHORTCUT_PATH\\Overleaf.lnk

    # Icon Pfad
    ICON_PATH=$(powershell.exe -Command "[Environment]::GetFolderPath('UserProfile')")
    ICON_PATH=$(echo "$ICON_PATH" | sed 's/\r//g')
    ICON_PATH=$ICON_PATH\\image.ico

    # Desktop-Verknüpfung erstellen
    TARGET_PATH="-d Ubuntu -e bash -c \"cd $LOCAL_PATH && sudo ./bin/overleaf_manager_script.sh\""
    echo "Lade das Icon herunter..."
    echo "${GRAY}"
    wget -O /mnt/c/image.ico "$ICON_LOCATION_URL"
    echo "${NC}"

    echo "Erstellen der Desktop-Verknüpfung..."
    echo "${GRAY}"

    powershell.exe -Command "
        \$WshShell = New-Object -ComObject WScript.Shell;
        \$shortcut = \$WshShell.CreateShortcut('$SHORTCUT_PATH');
        \$shortcut.Arguments = '$TARGET_PATH';
        \$shortcut.WorkingDirectory = \"C:\\Windows\\System32\";
        \$shortcut.TargetPath = \"C:\\Windows\\System32\\wsl.exe\";
        \$shortcut.IconLocation = \"C:\\image.ico\";
        \$shortcut.Save();
        "
    echo "${NC}"
    echo "Verknüpfung auf dem Desktop erstellt."

    if whiptail --title "Overleaf Installation" --yesno "Soll auch ein Startmenü Eintrag angelegt werden?" 8 78; then
        # Startmenü Eintrag erstellen
        echo "Erstelle Startmenü Eintrag..."
        echo "${GRAY}"
        START_MENU_PATH=$(powershell.exe -Command "[Environment]::GetFolderPath('StartMenu')")
        START_MENU_PATH=$(echo "$START_MENU_PATH" | sed 's/\r//g')
        START_MENU_PATH=$START_MENU_PATH\\Programs\\Overleaf.lnk

        powershell.exe -Command "
            \$WshShell = New-Object -ComObject WScript.Shell;
            \$shortcut = \$WshShell.CreateShortcut('$START_MENU_PATH');
            \$shortcut.Arguments = '$TARGET_PATH';
            \$shortcut.WorkingDirectory = \"C:\\Windows\\System32\";
            \$shortcut.TargetPath = \"C:\\Windows\\System32\\wsl.exe\";
            \$shortcut.IconLocation = \"C:\\image.ico\";
            \$shortcut.Save();
            "
        echo "${NC}"
        echo "Startmenü Eintrag erstellt."

        # Lege die Variable in einer Datei ab
        echo "export OVERLEAF_START_MENU_PATH=$START_MENU_PATH" >> "$EXEC_BIN_PATH/.shortcut_paths"
    fi
    # Lege die Variable in einer Datei ab
    echo "export OVERLEAF_SHORTCUT_PATH=$SHORTCUT_PATH" >> "$EXEC_BIN_PATH/.shortcut_paths"
fi