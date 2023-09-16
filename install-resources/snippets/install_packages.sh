#!/bin/bash

install_packages() {
    apt-get update
    apt-get install $DEPENCIES -y
    echo ""
    echo ""
    echo "$(cat $DEFINED_LANG/press_enter.txt)"
}