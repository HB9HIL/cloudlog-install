#!/bin/bashresources

# shellcheck disable=SC1090
# shellcheck disable=SC2086
# shellcheck disable=SC2024
# shellcheck disable=SC2005
# shellcheck disable=SC2120
# shellcheck source=/dev/null

# Variables
TMP_DIR=/tmp/cloudlog-tmp
DB_NAME=cloudlog
DB_USER=cloudloguser
DB_PASSWORD=$(openssl rand -base64 16)
INSTALL_PATH=/var/www/cloudlog
DEBUG_MODE=false
LOG_FILE=install-resources/log/installation.log 
MINIMUM_DEPENCIES="git dialog wget"
DEPENCIES="apache2 curl php-common php-curl php-mbstring php-mysql php-xml libapache2-mod-php"
CLOUDLOG_REPO="-b dev https://github.com/magicbug/Cloudlog.git"

export TMP_DIR
export DB_NAME
export DB_USER
export INSTALL_PATH
export DEBUG_MODE
export SQLREQUIRED
export LOG_FILE

# Set Variables (You shouldn't touch)
LOCAL_IP=$(ip -o -4 addr show scope global | awk '{split($4,a,"/");print a[1];exit}')
DEFINED_LANG=""

rm $LOG_FILE && touch $LOG_FILE

# Prepare language files
mkdir -p $TMP_DIR
cp -r install-resources $TMP_DIR

## Functions
errorstop() {
    # clear 
    echo "Uuups... Something went wrong here, Try to start the script again."
    echo "Please create an issue at https://github.com/HB9HIL/cloudlog-install/issues"
    echo "!!! ERRORSTOP !!!" >> $LOG_FILE
    local error_message="$1"
    echo "The script run into an error: $error_message" >&2 
    echo "The script run into an error: $error_message" >> "$LOG_FILE"
    read -r -p "Press Enter to stop the script. Restart it manually."
    exit 1
}
trap 'errorstop' ERR

calculating_box() {
    local content_file="$1"
    local lines
    lines=$(wc -l < "$content_file")
    local max_width=90
    local max_height=$((lines + 6))  # Adding a buffer for title and buttons
    echo "$max_height $max_width"
}

install_packages() {
    apt-get update
    apt-get install $DEPENCIES -y
    echo ""
    echo ""
    echo "$(cat $DEFINED_LANG/press_enter.txt)"
}

install_sql() {
    apt-get install mariadb-server -y
    echo ""
    echo ""
    echo "$(cat $DEFINED_LANG/press_enter.txt)"
}

securing_mysql() {
# Set your preferred secure installation options
MYSQL_ROOT_PASSWORD=""
UNIX_SOCKET="n"
CHANGE_ROOT_PWD="n"
REMOVE_ANONYMOUS_USERS="y" 
DISALLOW_ROOT_LOGIN_REMOTE="y"  
REMOVE_TEST_DATABASE="y"  
RELOAD_PRIVILEGE_TABLES="y"   

# Run mysql_secure_installation with predefined answers
echo "Configuring MySQL server..."

# Run mysql_secure_installation non-interactively with predefined answers
sudo mysql_secure_installation <<EOF
$MYSQL_ROOT_PASSWORD
$UNIX_SOCKET
$CHANGE_ROOT_PWD
$REMOVE_ANONYMOUS_USERS
$DISALLOW_ROOT_LOGIN_REMOTE
$REMOVE_TEST_DATABASE
$RELOAD_PRIVILEGE_TABLES
EOF

echo "MySQL secure installation completed."
}

# Minimum depencies Installation
DEFINED_LANG="$TMP_DIR/install-resources/text/english"
echo ">>>  apt-get update" >> $LOG_FILE
info_updating_dimensions=$(calculating_box "$DEFINED_LANG/info_updating.txt")
dialog --title "Update Repositories" --infobox "$(cat $DEFINED_LANG/info_updating.txt)" $info_updating_dimensions;  apt-get update >> $LOG_FILE

echo ">>>  apt-get upgrade -y" >> $LOG_FILE
info_upgrading_dimensions=$(calculating_box "$DEFINED_LANG/info_upgrading.txt")
dialog --title "Upgrade System" --infobox "$(cat $DEFINED_LANG/info_upgrading.txt)" $info_upgrading_dimensions;  apt-get upgrade -y >> $LOG_FILE

echo ">>>  apt-get install $MINIMUM_DEPENCIES -y" >> $LOG_FILE
info_installing_dimensions=$(calculating_box "$DEFINED_LANG/info_installing.txt")
dialog --title "Install Minimum Depencies" --infobox "$(cat $DEFINED_LANG/info_installing.txt)" $info_installing_dimensions;  apt-get install $MINIMUM_DEPENCIES -y >> $LOG_FILE


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
if dialog --title "Welcome" --msgbox "$(cat $DEFINED_LANG/welcome.txt)" $welcome_dimensions; then
    echo "User accepted Welcome Message" >> $LOG_FILE
else
    echo "User did not accept Welcome Message" >> $LOG_FILE
    clear
    exit 1
fi


# Database Setup
if dpkg -l | grep -E 'mysql-server|mariadb-server'; then
    echo "MySQL oder MariaDB found in system" >> $LOG_FILE
else    
    echo "MySQL oder MariaDB not found in system" >> $LOG_FILE
    install_sql | tee -a $LOG_FILE | dialog --no-ok --programbox "$(cat $DEFINED_LANG/sql_info.txt)" 40 120
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
dialog --title "$(cat $DEFINED_LANG/install.txt)" --msgbox "$(cat $DEFINED_LANG/install_info.txt)" $install_info_dimensions
install_packages | tee -a $LOG_FILE | dialog --no-ok --programbox "$(cat $DEFINED_LANG/install.txt)" 40 120
wait_info_dimensions=$(calculating_box "$DEFINED_LANG/wait_info.txt")
dialog --title "$(cat $DEFINED_LANG/install.txt)" --msgbox "$(cat $DEFINED_LANG/wait_info.txt)" $wait_info_dimensions

# Prepare the Database
{
securing_mysql
mysql -u root -e "CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD'"
mysql -u root -e "CREATE DATABASE $DB_NAME"
mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%'"
mysql -u root -e "FLUSH PRIVILEGES"
} >> $LOG_FILE

# Prepare the Webroot Folder
mkdir -p $INSTALL_PATH
git clone $CLOUDLOG_REPO $INSTALL_PATH >> $LOG_FILE

# Set the Permissions
{
chown -R root:www-data $INSTALL_PATH/application/config/
chown -R root:www-data $INSTALL_PATH/assets/qslcard/
chown -R root:www-data $INSTALL_PATH/backup/
chown -R root:www-data $INSTALL_PATH/updates/
chown -R root:www-data $INSTALL_PATH/uploads/
chown -R root:www-data $INSTALL_PATH/images/eqsl_card_images/
chmod -R g+rw $INSTALL_PATH/application/config/
chmod -R g+rw $INSTALL_PATH/assets/qslcard/
chmod -R g+rw $INSTALL_PATH/backup/
chmod -R g+rw $INSTALL_PATH/updates/
chmod -R g+rw $INSTALL_PATH/uploads/
chmod -R g+rw $INSTALL_PATH/images/eqsl_card_images/
} >> $LOG_FILE

# Configure Apache2
a2dissite 000-default.conf
a2enmod proxy_fcgi setenvif
a2enmod ssl

apache2_config_content=$(cat install-resources/apache2_config_cloudlog.conf)
echo "$apache2_config_content" | tee /etc/apache2/sites-available/cloudlog.conf >> $LOG_FILE

# Change Cloudlog's Developement Mode into Production Mode
sed -i "s/define('ENVIRONMENT', 'development');/define('ENVIRONMENT', 'production');/" $INSTALL_PATH/index.php

# Activate Apache2
a2ensite cloudlog.conf
cp $INSTALL_PATH/.htaccess.sample .htaccess

{
sed -i "s#\$DB_NAME#$DB_NAME#g" $DEFINED_LANG/final_message.txt
sed -i "s#\$DB_USER#$DB_USER#g" $DEFINED_LANG/final_message.txt
sed -i "s#\$DB_PASSWORD#$DB_PASSWORD#g" $DEFINED_LANG/final_message.txt
sed -i "s#\$LOCAL_IP#$LOCAL_IP#g" $DEFINED_LANG/final_message.txt
sed -i "s#\$INSTALL_PATH#$INSTALL_PATH#g" /etc/apache2/sites-available/cloudlog.conf
} >> $LOG_FILE

systemctl restart apache2
echo "Restart Apache2" >> $LOG_FILE

dialog --title "$(cat $DEFINED_LANG/install_successful.txt)" --msgbox "$(cat $DEFINED_LANG/final_message.txt)" 40 140

# Cleaning up
rm -r $TMP_DIR
cd && clear
