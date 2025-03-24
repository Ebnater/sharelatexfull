#!/bin/bash

# Überprüfen, ob Whiptail installiert ist
if ! command -v whiptail &> /dev/null; then
    echo "Whiptail ist nicht installiert. Bitte installieren Sie es zuerst."
    exit 1
fi

# Menü mit Whiptail anzeigen
OPTION=$(whiptail --title "Overleaf Manager Script" --menu "Wählen Sie eine Aktion aus:" 15 50 5 \
"1" "Starten" \
"2" "Stoppen" \
"3" "Updaten" \
"4" "Neustarten" \
"5" "Frage den Doktor" \
"6" "Version wechseln" \
"7" "Beenden" 3>&1 1>&2 2>&3)

# Überprüfen, ob der Benutzer abgebrochen hat
while do
    if [ $? -ne 0 ]; then
        echo "Abgebrochen."
        exit 1
    fi

    # Aktion basierend auf der Auswahl ausführen
    case $OPTION in
        1)
            echo "Starte bin/up..."
            ./bin/up
            echo "Stoppe den Container..."
            ./bin/docker-compose down
            ;;
        2)
            echo "Starte bin/stop..."
            ./bin/stop
            ./bin/docker-compose down
            ;;
        3)
            echo "Starte bin/upgrade..."
            ./bin/upgrade
            ;;
        4)
            echo "Starte bin/restart..."
            ./bin/restart
            ;;
        5)
            echo "Starte bin/doctor..."
            DOCTOR_OUTPUT=$(./bin/doctor 2>&1) # Capture the output of ./bin/doctor
            whiptail --title "bin/doctor Output" --msgbox "$DOCTOR_OUTPUT" 20 70
            ;;
        6)
            if [ -f ../configs/version ]; then
                CURRENT_VERSION=$(cat ../configs/version)
            else
                CURRENT_VERSION="Unbekannt"
            fi

            NEW_VERSION=$(whiptail --title "Version wechseln" --inputbox "Aktuelle Version: $CURRENT_VERSION\nGeben Sie die neue Version ein:" 10 60 "$CURRENT_VERSION" 3>&1 1>&2 2>&3)

            if [ $? -eq 0 ]; then
                echo "$NEW_VERSION" > ../configs/version
                whiptail --title "Erfolg" --msgbox "Die Version wurde auf $NEW_VERSION aktualisiert." 10 60
            else
                whiptail --title "Abgebrochen" --msgbox "Die Aktion wurde abgebrochen." 10 60
            fi
            ;;
        7)
            echo "Beenden..."
            exit 0
            ;;
        *)
            echo "Ungültige Auswahl."
            exit 1
            ;;
    esac
done