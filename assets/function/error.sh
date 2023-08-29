#!/bin/bash

errorstop() {
    clear 
    echo "Uuups... Something went wrong here, Try to start the script again."
    read -p "Press Enter to stop the script. Restart it manually."
}