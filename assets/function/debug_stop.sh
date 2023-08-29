#!/bin/bash

debug_stop() {
    if $DEBUG_MODE; then
        debug "Debug-Mode is active"
        read -r -p "Script stopped for debugging. Press Enter to continue or Strg+C to stop the script"
    fi
}

