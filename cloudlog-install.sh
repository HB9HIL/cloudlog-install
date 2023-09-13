#!/bin/bashresources

# shellcheck disable=SC1090
# shellcheck disable=SC2086
# shellcheck disable=SC2024
# shellcheck source=/dev/null

# Variables
TMP_DIR=/tmp/cloudlog-tmp
DB_NAME=cloudlog
DB_USER=cloudloguser
DB_PASSWORD=$(openssl rand -base64 16)
INSTALL_PATH=/var/www/cloudlog
DEBUG_MODE=false
LOG_FILE=install-resources/log/installation.log ## Don't change if you don't need to, file will be overwritten!
MINIMUM_DEPENCIES="git dialog wget" ## Minimum Depencies to run this script
DEPENCIES="apache2 curl php-common php-curl php-mbstring php-mysql php-xml libapache2-mod-php" ## Without mariadb-server

export TMP_DIR
export DB_NAME
export DB_USER
export INSTALL_PATH
export DEBUG_MODE
export SQLREQUIRED
export LOG_FILE

# Text Variables
INSTALL=$(cat $DEFINED_LANG/install.txt)
GIT_CLONE_INFO=$(cat $DEFINED_LANG/git_clone_info.txt)
PRESS_ENTER=$(cat $DEFINED_LANG/press_enter.txt)

# Set Variables (You shouldn't touch)
LOCAL_IP=$(ip -o -4 addr show scope global | awk '{split($4,a,"/");print a[1];exit}')
DEFINED_LANG=""

rm $LOG_FILE && touch $LOG_FILE

# Prepare language files
mkdir -p $TMP_DIR
cp -r install-resources $TMP_DIR

## Functions
errorstop() {
    clear 
    echo "Uuups... Something went wrong here, Try to start the script again."
    echo "Please create an issue at https://github.com/HB9HIL/cloudlog-install/issues"
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
    sudo apt-get update
    sudo apt-get install $DEPENCIES -y
    echo ""
    echo ""
    echo $PRESS_ENTER
}

install_sql() {
    sudo apt-get update
    sudo apt-get install mariadb-server -y
    echo ""
    echo ""
    echo $PRESS_ENTER
}

git_clone() {
    sudo git clone https://github.com/magicbug/Cloudlog.git $INSTALL_PATH
    echo ""
    echo ""
    echo $PRESS_ENTER
}

# Minimum depencies Installation
DEFINED_LANG="$TMP_DIR/install-resources/text/english"
echo ">>> sudo apt-get update" >> $LOG_FILE
info_updating_dimensions=$(calculating_box "$DEFINED_LANG/info_updating.txt")
dialog --title "Update Repositories" --infobox "$(cat $DEFINED_LANG/info_updating.txt)" $info_updating_dimensions; sudo apt-get update >> $LOG_FILE

echo ">>> sudo apt-get upgrade -y" >> $LOG_FILE
info_upgrading_dimensions=$(calculating_box "$DEFINED_LANG/info_upgrading.txt")
dialog --title "Upgrade System" --infobox "$(cat $DEFINED_LANG/info_upgrading.txt)" $info_upgrading_dimensions; sudo apt-get upgrade -y >> $LOG_FILE

echo ">>> sudo apt-get install $MINIMUM_DEPENCIES -y" >> $LOG_FILE
info_installing_dimensions=$(calculating_box "$DEFINED_LANG/info_installing.txt")
dialog --title "Install Minimum Depencies" --infobox "$(cat $DEFINED_LANG/info_installing.txt)" $info_installing_dimensions; sudo apt-get install $MINIMUM_DEPENCIES -y >> $LOG_FILE


# Choose language
LANG_CHOICE=$(dialog --stdout --menu "Choose a Language" 0 0 0 \
    1 "English" \
    2 "Deutsch") 
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


# Welcome Message
welcome_dimensions=$(calculating_box "$DEFINED_LANG/welcome.txt")
if dialog --title "Welcome" --yesno "$(cat $DEFINED_LANG/welcome.txt)" $welcome_dimensions; then
    echo "User accepted Welcome Message" >> $LOG_FILE
else
    echo "User did not accept Welcome Message" >> $LOG_FILE
    exit 1
fi


# Database Setup
sql_required_dimensions=$(calculating_box "$DEFINED_LANG/sql_required.txt")
if dialog --title "Need to install SQL?" --yesno "$(cat $DEFINED_LANG/sql_required.txt)" $sql_required_dimensions; then
    echo "User needs to have SQL installed" >> $LOG_FILE
    install_sql | tee -a $LOG_FILE | dialog --no-ok --programbox "$INSTALL" 40 120
else    
    echo "User already have SQL installed" >> $LOG_FILE
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
sed -i "s/\$DB_NAME/$DB_NAME/g" $DEFINED_LANG/sql_setupinfo.txt >> $LOG_FILE
sed -i "s/\$DB_USER/$DB_USER/g" $DEFINED_LANG/sql_setupinfo.txt >> $LOG_FILE

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

## Install all depencies
install_info_dimensions=$(calculating_box "$DEFINED_LANG/install_info.txt")
dialog --title "$INSTALL" --msgbox "$(cat $DEFINED_LANG/install_info.txt)" $install_info_dimensions
install_packages | tee -a $LOG_FILE | dialog --no-ok --programbox "$INSTALL" 40 120

# Prepare the Database
{
sudo mysql -u root -e "CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD'"
sudo mysql -u root -e "CREATE DATABASE $DB_NAME"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%'"
sudo mysql -u root -e "FLUSH PRIVILEGES"
} >> $LOG_FILE

# Prepare the Webroot Folder
sudo mkdir -p $INSTALL_PATH
clear
git_clone | tee -a $LOG_FILE | dialog --no-ok --programbox "$GIT_CLONE_INFO" 40 120

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

# Activate Apache2
sudo a2ensite cloudlog.conf
sudo systemctl restart apache2

clear
sed -i "s/\$DB_NAME/$DB_NAME/g" $DEFINED_LANG/final_message.txt >> $LOG_FILE
sed -i "s/\$DB_USER/$DB_USER/g" $DEFINED_LANG/final_message.txt >> $LOG_FILE
sed -i "s/\$DB_PASSWORD/$DB_PASSWORD/g" $DEFINED_LANG/final_message.txt >> $LOG_FILE
sed -i "s/\$LOCAL_IP/$LOCAL_IP/g" $DEFINED_LANG/final_message.txt >> $LOG_FILE


dialog --title "$(cat $DEFINED_LANG/install_successful.txt)" --msgbox "$(cat $DEFINED_LANG/final_message.txt)" 140 100
clear
sudo mysql_secure_installation
