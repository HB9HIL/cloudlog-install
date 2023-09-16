#!/bin/bash

WEBMASTER_EMAIL="yourmail@example.com"

# Set Variables (You shouldn't touch)
LOCAL_IP=$(ip -o -4 addr show scope global | awk '{split($4,a,"/");print a[1];exit}')
DEFINED_LANG=""
TMP_DIR=/tmp/cloudlog-tmp
DB_NAME=cloudlog
DB_USER=cloudloguser
DB_PASSWORD=$(openssl rand -base64 16)
INSTALL_PATH=/var/www/cloudlog
LOG_FILE=install-resources/log/installation.log 
MINIMUM_DEPENCIES="git dialog"
DEPENCIES="apache2 curl php-common php-curl php-mbstring php-mysql php-xml libapache2-mod-php"
CLOUDLOG_REPO="https://github.com/magicbug/Cloudlog.git"
APACHE_CONF_NAME=cloudlog.conf
APACHE_CONF_PATH=/etc/apache2/sites-available/$APACHE_CONF_NAME
DEFINED_LANG="$TMP_DIR/install-resources/text/english"

# export LOCAL_IP
# export DEFINED_LANG
# export TMP_DIR
# export DB_NAME
# export DB_USER
# export INSTALL_PATH
# export LOG_FILE
# export MINIMUM_DEPENCIES
# export DEPENCIES
# export CLOUDLOG_REPO
# export APACHE_CONF_NAME
# export APACHE_CONF_PATH