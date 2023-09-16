#!/bin/bash

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
