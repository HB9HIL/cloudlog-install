#!/bin/bash

calculating_box() {
    local content_file="$1"
    local lines
    lines=$(wc -l < "$content_file")
    local max_width=90
    local max_height=$((lines + 6))  # Adding a buffer for title and buttons
    echo "$max_height $max_width"
}