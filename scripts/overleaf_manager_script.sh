#!/bin/bash

MANAGER_SCRIPT_URL=https://git.serv.eserver.icu/ewbc/sharelatexfull/raw/branch/main/scripts/overleaf_manager_script.sh

# Colors
RED='\033[0;31m'
GRAY='\033[1;30m'
NC='\033[0m' # No Color

# Überprüfen, ob Whiptail installiert ist
if ! command -v whiptail &> /dev/null; then
    echo "Whiptail ist nicht installiert. Bitte installieren Sie es zuerst."
    exit 1
fi

# Check for new Manager Script Version
if [ -f bin/overleaf_manager_script.sh ]; then
    CURRENT_MD5=$(md5sum bin/overleaf_manager_script.sh | awk '{print $1}')
    NEW_MD5=$(curl -s $MANAGER_SCRIPT_URL | md5sum | awk '{print $1}')

    if [ "$CURRENT_MD5" != "$NEW_MD5" ]; then
        echo "Es gibt eine neue Version des Manager-Skripts. Möchten Sie es aktualisieren?"
        if whiptail --title "Manager-Skript aktualisieren" --yesno "Es gibt eine neue Version des Manager-Skripts. Möchten Sie es aktualisieren?" 8 78; then
            echo "Lade das neue Manager-Skript herunter..."
            echo -e "${GRAY}"
            wget -O bin/overleaf_manager_script.sh $MANAGER_SCRIPT_URL
            chmod +x bin/overleaf_manager_script.sh
            echo -e "${NC}"
            echo "Das Manager-Skript wurde aktualisiert."
        fi
    fi
else
    echo "Lade das Manager-Skript herunter..."
    echo -e "${GRAY}"
    wget -O bin/overleaf_manager_script.sh $MANAGER_SCRIPT_URL
    chmod +x bin/overleaf_manager_script.sh
    echo -e "${NC}"
    echo "Das Manager-Skript wurde heruntergeladen."
fi


# Menü mit Whiptail anzeigen
while :
do
    OPTION=$(whiptail --title "Overleaf Manager Script" --menu "Wählen Sie eine Aktion aus:" 15 50 5 \
    "1" "Starten" \
    "2" "Stoppen" \
    "3" "Updaten" \
    "4" "Shell" \
    "5" "Frage den Doktor" \
    "6" "Version wechseln" \
    "7" "Konfiguration anpassen" \
    "8" "Beenden" 3>&1 1>&2 2>&3)

    # Überprüfen, ob der Benutzer abgebrochen hat
    if [ $? -ne 0 ]; then
        echo "Abgebrochen."
        exit 1
    fi

    # Aktion basierend auf der Auswahl ausführen
    case $OPTION in
        1)
            echo "Starte bin/up..."
            if whiptail --title "Starte Overleaf" --yesno "Von dem Logs detachen?" 8 78; then
                echo -e "${GRAY}" # Set text color to gray
                ./bin/up -d
                echo -e "${NC}" # Reset text color
            else
                ./bin/up
            fi
            ;;
        2)
            echo "Starte bin/stop..."
            echo -e "${GRAY}"
            ./bin/stop
            ./bin/docker-compose down
            echo -e "${NC}"
            ;;
        3)
            echo "Starte bin/upgrade..."
            echo -e "${GRAY}"
            ./bin/upgrade
            echo -e "${NC}"
            ;;
        4)
            echo "Starte bin/shell..."
            ./bin/shell
            ;;
        5)
            echo "Starte bin/doctor..."
            DOCTOR_OUTPUT=$(./bin/doctor 2>&1) # Capture the output of ./bin/doctor
            whiptail --title "bin/doctor Output" --msgbox --scrolltext "$DOCTOR_OUTPUT" 20 70
            ;;
        6)
            if [ -f config/version ]; then
                CURRENT_VERSION=$(cat config/version)
            else
                CURRENT_VERSION="Unbekannt"
            fi

            NEW_VERSION=$(whiptail --title "Version wechseln" --inputbox "Aktuelle Version: $CURRENT_VERSION\nGeben Sie die neue Version ein:" 10 60 "$CURRENT_VERSION" 3>&1 1>&2 2>&3)

            if [ $? -eq 0 ]; then
                echo "$NEW_VERSION" > config/version
                whiptail --title "Erfolg" --msgbox "Die Version wurde auf $NEW_VERSION aktualisiert." 10 60
            else
                whiptail --title "Abgebrochen" --msgbox "Die Aktion wurde abgebrochen." 10 60
            fi
            ;;
        7)
            if [ -f config/overleaf.rc ]; then
                CONFIG_FILE_PATH=config/overleaf.rc
            else
                echo "Konfigurationsdatei nicht gefunden."
                exit 1
            fi

            # Vorläfige Implementierung
            nano $CONFIG_FILE_PATH
            ;;
        8)
            echo -e "${RED}"
            echo "Beenden..."
            exit 0
            ;;
        *)
            echo -e "${RED}"
            echo "Ungültige Auswahl."
            exit 1
            ;;
    esac
done