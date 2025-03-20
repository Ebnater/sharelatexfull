#!/bin/bash

CUSTOM_IMAGE_URL=git.serv.eserver.icu/ewbc/sharelatexfull

# Überprüfen, ob Docker installiert ist
if ! command -v docker &> /dev/null; then
    echo "Docker wird installiert..."
    # Docker-Installation
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
    echo "Docker wurde installiert."
else
    echo "Docker ist bereits installiert."
fi

# Git-Repository klonen
REPO_URL="https://github.com/overleaf/toolkit.git"
LOCAL_PATH="$HOME/overleaf-toolkit"
if [ ! -d "$LOCAL_PATH" ]; then
    echo "Klonen des Git-Repositories..."
    git clone "$REPO_URL" "$LOCAL_PATH"
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

# Finde Desktop Pfad
SHORTCUT_PATH=$(powershell.exe -Command "[Environment]::GetFolderPath('Desktop')")
SHORTCUT_PATH=$(echo "$SHORTCUT_PATH" | sed 's/\r//g')
SHORTCUT_PATH=$SHORTCUT_PATH\\Overleaf.lnk

# Desktop-Verknüpfung erstellen
TARGET_PATH="-d Ubuntu -e bash -c \"cd $LOCAL_PATH && sudo ./bin/up\""

echo "Erstellen der Desktop-Verknüpfung..."

powershell.exe -Command "
    \$WshShell = New-Object -ComObject WScript.Shell;
    \$shortcut = \$WshShell.CreateShortcut('$SHORTCUT_PATH');
    \$shortcut.Arguments = '$TARGET_PATH';
    \$shortcut.WorkingDirectory = \"C:\\Windows\\System32\";
    \$shortcut.TargetPath = \"C:\\Windows\\System32\\wsl.exe\";
    \$shortcut.Save();
    "
echo "Verknüpfung auf dem Desktop erstellt."