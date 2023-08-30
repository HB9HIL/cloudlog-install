#!/bin/bashresources

# shellcheck disable=SC1090
# shellcheck disable=SC2086
# shellcheck disable=SC2024
# shellcheck source=/dev/null

source install-config.env

rm $LOG_FILE && touch $LOG_FILE

# Prepare language files
mkdir -p $TMP_DIR
cp -r install-resources $TMP_DIR

## Functions

# Debug Mode
while [[ $# -gt 0 ]]; do
    case "$1" in
        --debug)
            DEBUG_MODE=true
            shift
            ;;
        *)
            echo "Unknown Option: $1"
            exit 1
            ;;
    esac
done
debug_stop() {
    if $DEBUG_MODE; then
        echo "!!! Debug-Mode is active. Script stopped" >> $LOG_FILE
        read -r -p "Script stopped for debugging. Press Enter to continue or Strg+C to stop the script"
        clear
    fi
}

errorstop() {
    clear 
    echo "Uuups... Something went wrong here, Try to start the script again."
    echo "!!! ERRORSTOP" >> $LOG_FILE
    read -r -p "Press Enter to stop the script. Restart it manually."
}

calculating_box() {
    local content_file="$1"
    local lines
    lines=$(wc -l < "$content_file")
    local max_width=90
    local max_height=$((lines + 10))  # Adding a buffer for title and buttons
    echo "$max_height $max_width"
}

install_packages() {
    sudo apt-get update && sudo apt-get install $DEPENCIES -y && echo "" && echo "" && echo $PRESS_ENTER
}

install_sql() {
    sudo apt-get update && sudo apt-get install mariadb-server -y && echo "" && echo "" && echo $PRESS_ENTER
}

# Minimum depencies Installation
    DEFINED_LANG="$TMP_DIR/install-resources/text/english"
    echo ">>> sudo apt-get update" >> $LOG_FILE
    info_updating_dimensions=$(calculating_box "$DEFINED_LANG/info_updating.txt")
    dialog --title "Update Repositories" --infobox "$(cat $DEFINED_LANG/info_updating.txt)" $info_updating_dimensions; sudo apt-get update >> $LOG_FILE

    echo ">>> sudo apt-get upgrade -y" >> $LOG_FILE
    info_upgrading_dimensions=$(calculating_box "$DEFINED_LANG/info_upgrading.txt")
    dialog --title "Upgrade System" --infobox "$(cat $DEFINED_LANG/info_upgrading.txt)" $info_upgrading_dimensions; sudo apt-get upgrade -y >> $LOG_FILE

    echo ">>> sudo apt-get install git dialog -y" >> $LOG_FILE
    info_installing_dimensions=$(calculating_box "$DEFINED_LANG/info_installing.txt")
    dialog --title "Install Minimum Depencies" --infobox "$(cat $DEFINED_LANG/info_installing.txt)" $info_installing_dimensions; sudo apt-get install $MINIMUM_DEPENCIES -y >> $LOG_FILE


# Choose language
LANG_CHOICE=$(dialog --stdout --menu "Choose a Language" 0 0 0 \
    1 "English" \
    2 "Deutsch") # \
#   3 [more languages] )

# Set the DEFINED_LANG Variable
if [ "$LANG_CHOICE" == "1" ]; then
    echo "User chose english" >> $LOG_FILE
    DEFINED_LANG="$TMP_DIR/install-resources/text/english"
elif [ "$LANG_CHOICE" == "2" ]; then
    echo "User chose german" >> $LOG_FILE
    DEFINED_LANG="$TMP_DIR/install-resources/text/german"
# elif [ "$LANG_CHOICE" == "[more numbers]" ]; then
#    echo "User chose [language]" >> $LOG_FILE
#    DEFINED_LANG="$TMP_DIR/install-resources/text/[more languages]"
else
    errorstop
fi
debug_stop

# Welcome Message
welcome_dimensions=$(calculating_box "$DEFINED_LANG/welcome.txt")
if dialog --title "Welcome" --yesno "$(cat $DEFINED_LANG/welcome.txt)" $welcome_dimensions; then
    echo "User accepted Welcome Message" >> $LOG_FILE
else
    echo "User did not accept Welcome Message" >> $LOG_FILE
    exit 1
fi
debug_stop

# Database Setup
sql_required_dimensions=$(calculating_box "$DEFINED_LANG/sql_required.txt")
if dialog --title "Need to install SQL?" --yesno "$(cat $DEFINED_LANG/sql_required.txt)" $sql_required_dimensions; then
    echo "User needs to have SQL installed" >> $LOG_FILE
    install_sql | tee -a $LOG_FILE | dialog --no-ok --programbox "$INSTALL " 20 80
else    
    echo "User already have SQL installed" >> $LOG_FILE
    SQLREQUIRED=false
    sql_info_dimensions=$(calculating_box "$DEFINED_LANG/sql_info.txt")
    if dialog --title "SQL needs to be on this server" --yesno "$(cat $DEFINED_LANG/sql_info.txt)" $sql_info_dimensions; then
        echo "User Input: SQL Server is running on this server" >> $LOG_FILE
    else
        echo "!!! User Input: SQL Server is running on an external Server" >> $LOG_FILE
        sql_external_nosupport_dimensions=$(calculating_box "$DEFINED_LANG/sql_external_nosupport.txt")
        dialog --title "ERROR - External SQL" --textbox "$(cat $DEFINED_LANG/sql_external_nosupport.txt)" $sql_external_nosupport_dimensions
        exit 1
    fi
fi

# Prepare sql_setupinfo.txt
sed -i "s/\$DB_NAME/$DB_NAME/g" $DEFINED_LANG/sql_setupinfo.txt > /dev/null
sed -i "s/\$DB_USER/$DB_USER/g" $DEFINED_LANG/sql_setupinfo.txt > /dev/null

sql_setupinfo_dimensions=$(calculating_box "$DEFINED_LANG/sql_setupinfo.txt")
if dialog --title "SQL Setup" --yesno "$(cat $DEFINED_LANG/sql_setupinfo.txt)" $sql_setupinfo_dimensions; then
    echo "User Input: User accepted the default credetials for the database setup. Password will be automatically generated" >> $LOG_FILE
else
    sql_dbname_dimensions=$(calculating_box "$DEFINED_LANG/sql_dbname.txt")
    DB_NAME=$(dialog --title "SQL Setup" --inputbox "$(cat $DEFINED_LANG/sql_dbname.txt)" $sql_dbname_dimensions 3>&1 1>&2 2>&3)
    echo "User set Database Name to '$DB_NAME'" >> $LOG_FILE

    sql_dbuser_dimensions=$(calculating_box "$DEFINED_LANG/sql_dbuser.txt")
    DB_USER=$(dialog --title "SQL Setup" --inputbox "$(cat $DEFINED_LANG/sql_dbuser.txt)" $sql_dbuser_dimensions 3>&1 1>&2 2>&3)
    echo "User set Database User to '$DB_USER'" >> $LOG_FILE

    sql_dbpassword_dimensions=$(calculating_box "$DEFINED_LANG/sql_dbpassword.txt")
    DB_PASSWORD=$(dialog --title "SQL Setup" --passwordbox "$(cat $DEFINED_LANG/sql_dbpassword.txt)" $sql_dbpassword_dimensions 3>&1 1>&2 2>&3)
    echo "User set a Password for the Database User - Hidden for Security" >> $LOG_FILE
fi
debug_stop

## Install all depencies
    install_packages | tee -a $LOG_FILE | dialog --no-ok --programbox "$INSTALL " 20 80


##################################################################################################################################
#######                                                                                                                    #######
clear && exit 1 ####################################     EDITED UNTIL HERE     ###################################################
#######                                                                                                                    #######
##################################################################################################################################

# Prepare the Database

sudo mysql -u root -e "CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD'"
sudo mysql -u root -e "CREATE DATABASE $DB_NAME"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%'"
sudo mysql -u root -e "FLUSH PRIVILEGES"

# Prepare the Webroot Folder

sudo mkdir -p $INSTALL_PATH && sudo git clone -b dev https://github.com/magicbug/Cloudlog.git $INSTALL_PATH

# Set the Permissions

sudo chown -R root:www-data $INSTALL_PATH/application/config/
sudo chown -R root:www-data $INSTALL_PATH/assets/qslcard/
sudo chown -R root:www-data $INSTALL_PATH/backup/
sudo chown -R root:www-data $INSTALL_PATH/updates/
sudo chown -R root:www-data $INSTALL_PATH/uploads/
sudo chown -R root:www-data $INSTALL_PATH/images/eqsl_card_images/
sudo chmod -R g+rw $INSTALL_PATH/application/config/
sudo chmod -R g+rw $INSTALL_PATH/assets/qslcard/
sudo chmod -R g+rw $INSTALL_PATH/backup/
sudo chmod -R g+rw $INSTALL_PATH/updates/
sudo chmod -R g+rw $INSTALL_PATH/uploads/
sudo chmod -R g+rw $INSTALL_PATH/images/eqsl_card_images/

# Configure Apache2
sudo a2dissite 000-default.conf
sudo a2enmod proxy_fcgi setenvif
sudo a2enmod ssl

apache2_config_content=$(cat install-resources/apache2_config_cloudlog.conf)
echo "$apache2_config_content" | sudo tee /etc/apache2/sites-available/cloudlog.conf > /dev/null

# Change Cloudlog's Developement Mode into Production Mode
sed -i "s/define('ENVIRONMENT', 'development');/define('ENVIRONMENT', 'production');/" "$INSTALL_PATH/index.php"

sudo a2ensite cloudlog.conf
sudo systemctl restart apache2

# End Message
FIELD_W=30
ENTRY_W=60

echo ""
echo ""
echo ""
echo "_____________________________________________________________________________________________________"
echo ""
echo ""
echo ""

if [[ $language =~ ^($CHOOSELANG)$ ]]; then
    echo ">>> The script is now complete."
    echo ""
    echo "Access the following address with your web browser: http://$LOCAL_IP/install"
    echo ""
    echo "!!! Write down the DB_PASSWORD at a safe place !!!"
    echo ""
    echo "Now enter the following data in the installer. Note that any reverse proxy must be configured BEFORE clicking 'Install':"
    echo ""
    # Function to create a row in the table
    print_table_row() {
            local field_width=$((FIELD_W - 1))
            local entry_width=$((ENTRY_W - 1))
            local field=$1
            local entry=$2

            printf "| %-${field_width}s | %-${entry_width}s |\n" "$field" "$entry"
    }

    # output of the table
    echo "+$(printf -- '-%.0s' $(seq $((FIELD_W+1))))+$(printf -- '-%.0s' $(seq $((ENTRY_W+1))))+" 
    echo "| $(printf -- '%-*s' $((FIELD_W-1)) "Feld") | $(printf -- '%-*s' $((ENTRY_W-1)) "Eintrag") |"
    echo "+$(printf -- '-%.0s' $(seq $((FIELD_W+1))))+$(printf -- '-%.0s' $(seq $((ENTRY_W+1))))+"

    print_table_row "DIRECTORY" "left empty or '$INSTALL_PATH'"
    print_table_row "Webseite URL" "planned URL to reach Cloudlog"
    print_table_row "Default Gridsquare" "your local Maidenhead-Locator"
    print_table_row "hostname" "localhost"
    print_table_row "Username" "$DB_USER"
    print_table_row "Password" "$DB_PASSWORD"
    print_table_row "Database Name" "$DB_NAME"

    echo "+$(printf -- '-%.0s' $(seq -s ' ' $((FIELD_W+1))))+$(printf -- '-%.0s' $(seq -s ' ' $((ENTRY_W+1))))+"""
    echo ""
    echo "Afterwards, click on 'Install'."
    echo "Congratulations. You can now log in at http://$LOCAL_IP/ or the URL you have set in the 'Website URL' field with the demo credentials."
    echo "When you have completed the install wizard, do the following:"
    echo "    - Log in with username m0abc and password demo"
    echo "    - Create a new admin account (Admin Dropdown) and delete the demo account"
    echo "    - Update Country Files (Admin Dropdown)"
    echo "    - Create a station profile (Admin Dropdown) and set it as active"
    echo "    - If you want to know if the person you're working uses LoTW, run: http://$LOCAL_IP/index.php/lotw/load_users. This is the initial run, but we'll run this every week from cron momentarily."
    echo ""
    echo "Thank you for using this script. If you encounter any issues, please contact support@hb9hil.org for assistance."
    echo "The MySQL (MariaDB) installation will now be secured using 'sudo mysql_secure_installation' as a last step"
    echo ""
    echo ""
    read -r -p "Press Enter to continue..."
    sudo mysql_secure_installation

else
    echo ">>> Das Script ist nun fertig."
    echo ""
    echo "Rufen Sie mit Ihrem Webbrowser folgende Adresse auf: http://$LOCAL_IP/install"
    echo ""
    echo "!!! Notieren Sie sich das DB_PASSWORD an einem sicheren Ort !!!"
    echo ""
    echo "In dem Installer geben Sie nun folgende Daten ein. Beachten Sie, dass ein allfälliger Reverse Proxy konfiguriert werden muss BEVOR man auf 'Install' klickt:"
    echo ""
    # Funktion zum Erstellen einer Zeile in der Tabelle
    print_table_row() {
            local field_width=$((FIELD_W - 1))
            local entry_width=$((ENTRY_W - 1))
            local field=$1
            local entry=$2

            printf "| %-${field_width}s | %-${entry_width}s |\n" "$field" "$entry"
    }

    # Ausgabe der Tabelle
    echo "+$(printf -- '-%.0s' $(seq $((FIELD_W+1))))+$(printf -- '-%.0s' $(seq $((ENTRY_W+1))))+"
    echo "| $(printf -- '%-*s' $((FIELD_W-1)) "Feld") | $(printf -- '%-*s' $((ENTRY_W-1)) "Eintrag") |"
    echo "+$(printf -- '-%.0s' $(seq $((FIELD_W+1))))+$(printf -- '-%.0s' $(seq $((ENTRY_W+1))))+"

    print_table_row "DIRECTORY" "leer lassen oder '$INSTALL_PATH'"
    print_table_row "Webseite URL" "geplante URL wie Cloudlog erreicht werden soll"
    print_table_row "Default Gridsquare" "Dein lokaler Maidenhead-Locator"
    print_table_row "hostname" "localhost"
    print_table_row "Username" "$DB_USER"
    print_table_row "Password" "$DB_PASSWORD"
    print_table_row "Database Name" "$DB_NAME"

    echo "+$(printf -- '-%.0s' $(seq -s ' ' $((FIELD_W+1))))+$(printf -- '-%.0s' $(seq -s ' ' $((ENTRY_W+1))))+"

    echo ""
    echo "Klicken Sie anschließend auf 'Installieren'."
    echo "Herzlichen Glückwunsch. Sie können sich jetzt unter http://$LOCAL_IP/ oder der URL, die Sie im Feld 'Website URL' festgelegt haben, mit den Demo-Anmeldedaten anmelden."
    echo "Wenn Sie den Installationsassistenten abgeschlossen haben, führen Sie bitte folgende Schritte aus:"
    echo "    - Melden Sie sich mit Benutzername m0abc und Passwort demo an"
    echo "    - Erstellen Sie ein neues Administrator-Konto (Administrator-Dropdown) und löschen Sie das Demo-Konto"
    echo "    - Aktualisieren Sie Länderdateien (Administrator-Dropdown)"
    echo "    - Erstellen Sie ein Stationsprofil (Administrator-Dropdown) und setzen Sie es als aktiv"
    echo "    - Wenn Sie wissen möchten, ob die Person, mit der Sie arbeiten, LoTW verwendet, führen Sie Folgendes aus: http://$LOCAL_IP/index.php/lotw/load_users. Dies ist der erste Durchlauf, aber wir werden dies wöchentlich aus dem Cron ausführen."
    echo ""
    echo "Vielen Dank, dass Sie dieses Skript verwenden. Wenn Sie auf Probleme stoßen, wenden Sie sich bitte an support@hb9hil.org, um Unterstützung zu erhalten."
    echo "Die MySQL (MariaDB)-Installation wird nun als letzter Schritt noch mit 'sudo mysql_secure_installation' abgesichert."
    echo ""
    echo ""
    read -r -p "Drücken Sie die Eingabetaste, um fortzufahren..."
    sudo mysql_secure_installation
fi
