#!/bin/bash

set_permissions() {
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