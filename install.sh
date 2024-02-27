#!/bin/bash
home_dir=$(echo ~)
dxtools_path="/opt/dxtools"
script_dir=$(dirname "$0")

folder_path_temp="$1"

if [[ -z "$folder_path_temp" ]]; then
    folder_path="$dxtools_path"
else
    folder_path="$folder_path_temp"
fi

# Updating default user configuration
mkdir -p $home_dir/.dx
cp -r $script_dir/.dx/* $home_dir/.dx
chmod +x $home_dir/.dx/*.sh

# Copying the scripts to the desired folder
mkdir -p $folder_path
cp -r $script_dir/* $folder_path
chmod +x $folder_path/*.sh
chmod +x $folder_path/scripts/*.sh

find "$folder_path/." -type f -name "*.sh" -exec sed -i "s|dxtools_path=\"/opt/dxtools\"|dxtools_path=\"$folder_path\"|g" {} \;

$folder_path/dx.sh config init
$folder_path/dx.sh config show
