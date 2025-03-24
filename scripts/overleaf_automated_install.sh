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
if ! command -v docker &> /dev/null && whiptail --title "Docker Installation" --yesno "Docker ist nicht installiert. Soll es installiert werden?" 8 78; then
    # Docker-Installation
    echo "Installiere Docker..."
    echo "${GRAY}"
    sudo apt update
    sudo apt install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo \
  	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  	$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo "${NC}"
    echo "Docker wurde installiert."
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

    # Desktop-Verknüpfung erstellen
    TARGET_PATH="-d Ubuntu -e bash -c \"cd $LOCAL_PATH && sudo ./bin/overleaf_manager_script.sh\""
    echo "Lade das Icon herunter..."
    echo "${GRAY}"
    wget -O /mnt/c/temp/image.ico "$ICON_LOCATION_URL"
    echo "${NC}"

    echo "Erstellen der Desktop-Verknüpfung..."
    echo "${GRAY}"

    powershell.exe -Command "
        \$WshShell = New-Object -ComObject WScript.Shell;
        \$shortcut = \$WshShell.CreateShortcut('$SHORTCUT_PATH');
        \$shortcut.Arguments = '$TARGET_PATH';
        \$shortcut.WorkingDirectory = \"C:\\Windows\\System32\";
        \$shortcut.TargetPath = \"C:\\Windows\\System32\\wsl.exe\";
        \$shortcut.IconLocation = \"C:\\temp\\image.ico\";
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
        START_MENU_PATH=$START_MENU_PATH\\Programs\\Overleaf Manager.lnk

        powershell.exe -Command "
            \$WshShell = New-Object -ComObject WScript.Shell;
            \$shortcut = \$WshShell.CreateShortcut('$START_MENU_PATH');
            \$shortcut.Arguments = '$TARGET_PATH';
            \$shortcut.WorkingDirectory = \"C:\\Windows\\System32\";
            \$shortcut.TargetPath = \"C:\\Windows\\System32\\wsl.exe\";
            \$shortcut.IconLocation = \"C:\\temp\\image.ico\";
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