#!/bin/bash

# Set Variables (You shouldn't touch)

CHOOSELANG="[eE][nN][gG][lL][iI][sS][hH]|[eE]"
ANSWER="[yY][eE][sS]|[yY]|[jJ][aA]|[jJ]"
LOCAL_IP=$(ip -o -4 addr show scope global | awk '{split($4,a,"/");print a[1];exit}')

# Editable Variables
DB_NAME=cloudlog
DB_USER=cloudloguser
DB_PASSWORD=$(openssl rand -base64 16)
INSTALL_PATH=/var/www/cloudlog


clear

# Choose language
echo "Bitte wähle deine Sprache"
read -p "Please select your language (E)nglish/(G)erman: " language
echo ""
echo ""

# Welcome in the choosen language

if [[ $language =~ ^($CHOOSELANG)$ ]]; then
    echo "Welcome to this installation of Cloudlog."
    echo "This script for the installation and shows the last necessary steps at the end."
    echo "Various passwords will be displayed to you. Also have the sudo password ready."
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! You should write down these passwords in a safe place !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo ""
    # Yes/No
    read -p "All Right? (yes/no): " answer
else
    echo "Herzlich Willkommen zu dieser Installation von Cloudlog."
    echo "Dieses Script für die Installation aus und zeigt am Schluss die letzten Notwendigen Schritte an."
    echo "Dabei werden Ihnen diverse Passwörter angezeigt. Halten Sie zudem das Sudo-Passwort bereit."
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! Diese Passwörter sollten Sie sich an einem sicheren Ort notieren !!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo ""
    # Yes/No
    read -p "Alles klar? (ja/nein): " answer
fi

echo ""
echo ""

# Check the answer

if [[ $answer =~ ^($ANSWER)$ ]]; then
    if [[ $language =~ ^($CHOOSELANG)$ ]]; then 
        echo "Great, the script will proceed."
    else
        echo "Super, dann können wir weiter machen!"
    fi
else
    if [[ $language =~ ^($CHOOSELANG)$ ]]; then 
        echo "Ok, too bad. The script will be aborted. If needed, restart the script."
        exit 1
    else
        echo "OK, schade. Dann hören wir hier mal auf. Starte ggf. neu"
        exit 1
    fi
fi
echo ""
sleep 2

# Updates
if [[ $language =~ ^($CHOOSELANG)$ ]]; then
    echo ">>> The system will now install updates."
    echo ""
else
    echo ">>> Das System wird nun Updates installieren."
    echo ""
fi
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
echo ""

# Installation of required packages

if [[ $language =~ ^($CHOOSELANG)$ ]]; then
    echo ">>> The system will now install the required packages."
    echo ""
else
    echo ">>> Es werden nun die benötigten Pakete installiert."
    echo ""
fi
# sudo add-apt-repository ppa:ondrej/php
sudo apt update
sudo apt install apache2 mariadb-server nano git curl vim wget -y
sudo apt install php php-{cli,common,curl,fpm,gd,imap,json,mbstring,mysql,opcache,readline,xml} libapache2-mod-php -y
sudo systemctl enable apache2

# Write php version tag to a variable
php_v=$(php -v | grep -oP 'PHP \K[0-9]+\.[0-9]+')

# Prepare the Database

sudo mysql -u root -e "CREATE USER '$DB_USER'@localhost IDENTIFIED BY '$DB_PASSWORD'"
sudo mysql -u root -e "CREATE DATABASE $DB_NAME"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost'"
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
sudo a2enconf php$php_v-fpm
sudo a2enmod ssl

config_content=$(cat << EOF
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot $INSTALL_PATH
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
)
echo "$config_content" | sudo tee /etc/apache2/sites-available/cloudlog.conf > /dev/null

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
    echo ""
    echo "Congratulations. You can now log in at http://$LOCAL_IP/ or the URL you have set in the 'Website URL' field."
    echo "Thank you for using this script. If you encounter any issues, please contact support@hb9hil.org for assistance."
    echo "Ideally you also run 'sudo mysql_secure_installation'"
    echo "This is described on https://www.hb9hil.org/cloudlog-auf-einen-linux-server-installieren/ under step 2."
    echo ""

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
    echo "Anschliessen klicken Sie auf 'Install'"
    echo ""
    echo "Herzlichen Glückwunsch. Sie können sich nun unter http://$LOCAL_IP/ oder der von Ihnen eingestellten URL bei 'Webseite URL' anmelden."
    echo "Danke für die Verwendung dieses Scripts. Sollten Probleme auftreten erhalten Sie unter support@hb9hil.org Hilfe."
    echo "Idealerweise führen Sie noch 'sudo mysql_secure_installation aus'"
    echo "Dies ist auf https://www.hb9hil.org/cloudlog-auf-einem-linux-server-installieren/ unter Schritt 2 beschrieben"
    echo ""
fi
