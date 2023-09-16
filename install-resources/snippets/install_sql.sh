#!/bin/bash

install_sql() {
    apt-get install mariadb-server -y
    echo ""
    echo ""
    echo "$(cat $DEFINED_LANG/press_enter.txt)"
}