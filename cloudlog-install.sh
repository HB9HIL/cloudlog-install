#!/bin/bashresources

# Include Snippets
SNIPPETS_DIR=install-resources/snippets
chmod 755 config.sh
chmod -R 755 $SNIPPETS_DIR
source config.sh
if [ -d "$SNIPPETS_DIR" ]; then
    for snippet_file in "$SNIPPETS_DIR"/*.sh; do
        if [ -f "$snippet_file" ] && [ -x "$snippet_file" ]; then
            source "$snippet_file"
        else
            echo "Error: Cannot execute file '$snippet_file'."
        fi
    done
else
    clear
    echo "Error: The 'snippets' directory does not exist."
    exit 1
fi

trap 'errorstop' ERR

# Clear the Log
> $LOG_FILE

# Prepare language files
mkdir -p $TMP_DIR
cp -r install-resources $TMP_DIR

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

# Set Mail Adress for the Webmaster
webmaster_email_dimensions=$(calculating_box "$DEFINED_LANG/webmaster_email.txt")
WEBMASTER_EMAIL=$(dialog --title "Webmaster E-Mail" --inputbox "$(cat $DEFINED_LANG/webmaster_email.txt)" $webmaster_email_dimensions 3>&1 1>&2 2>&3)
echo "User set Webmaster E-Mail Adress to '$WEBMASTER_EMAIL'" >> $LOG_FILE

# Database Setup
if dpkg -l | grep -E 'mysql-server|mariadb-server'; then
    echo "MySQL oder MariaDB found in system" >> $LOG_FILE
else    
    echo "MySQL oder MariaDB not found in system" >> $LOG_FILE
    install_sql | tee -a $LOG_FILE | dialog --no-ok --programbox "$(cat $DEFINED_LANG/sql_info.txt)" 40 120
    securing_mysql >> $LOG_FILE
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
mysql -u root -e "CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD'"
mysql -u root -e "CREATE DATABASE $DB_NAME"
mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%'"
mysql -u root -e "FLUSH PRIVILEGES"
} >> $LOG_FILE

# Prepare the Webroot Folder
mkdir -p $INSTALL_PATH
git clone $CLOUDLOG_REPO $INSTALL_PATH >> $LOG_FILE

# Set the Permissions
set_permissions

# Configure Apache2
a2dissite 000-default.conf
a2enmod proxy_fcgi setenvif ssl

apache2_config_content=$(cat install-resources/apache2_config_cloudlog.conf)
echo "$apache2_config_content" | tee $APACHE_CONF_PATH >> $LOG_FILE
sed -i "s#\$INSTALL_PATH#$INSTALL_PATH#g" $APACHE_CONF_PATH
sed -i "s#\$WEBMASTER_EMAIL#$WEBMASTER_EMAIL#g" $APACHE_CONF_PATH
a2ensite $APACHE_CONF_NAME
cp $INSTALL_PATH/.htaccess.sample .htaccess
systemctl restart apache2
echo "Restart Apache2" >> $LOG_FILE

# Change Cloudlog's Developement Mode into Production Mode
sed -i "s/define('ENVIRONMENT', 'development');/define('ENVIRONMENT', 'production');/" $INSTALL_PATH/index.php

{
sed -i "s#\$DB_NAME#$DB_NAME#g" $DEFINED_LANG/final_message.txt
sed -i "s#\$DB_USER#$DB_USER#g" $DEFINED_LANG/final_message.txt
sed -i "s#\$DB_PASSWORD#$DB_PASSWORD#g" $DEFINED_LANG/final_message.txt
sed -i "s#\$LOCAL_IP#$LOCAL_IP#g" $DEFINED_LANG/final_message.txt
} >> $LOG_FILE

#dialog --title "$(cat $DEFINED_LANG/install_successful.txt)" --msgbox "$(cat $DEFINED_LANG/final_message.txt)" 40 140
clear
echo $(cat $DEFINED_LANG/final_message.txt)
read -r

# Cleaning up
DB_PASSWORD="hidden"
rm -r $TMP_DIR
cd && clear
