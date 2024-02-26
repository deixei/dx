#!/bin/bash
dxtools_path="/opt/dxtools"

folder_path_temp="$1"

if [[ -z "$folder_path_temp" ]]; then
    folder_path="/opt/dxtools"
else
    folder_path="$folder_path_temp"
fi

current_dir=$(dirname "$0")
