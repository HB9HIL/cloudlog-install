#!/bin/bash

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
mysql_secure_installation <<EOF
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