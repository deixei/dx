#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi
dxtools_path="/opt/dxtools"
script_dir=$(dirname "$0")
# Default values
folder_path="$dxtools_path"
home_dir=$(echo ~)

# Parse named parameters
while [[ $# -gt 0 ]]; do
    case $1 in
        --tools_folder)
        folder_path=$2
        shift
        ;;
        --user_path)
        home_dir=$2
        shift
        ;;
    esac
    shift
done

# Copying the scripts to the desired folder
mkdir -p $folder_path
cp -r $script_dir/* $folder_path
chmod +x $folder_path/*.sh
chmod +x $folder_path/scripts/*.sh

find "$folder_path/." -type f -name "*.sh" -exec sed -i "s|dxtools_path=\"/opt/dxtools\"|dxtools_path=\"$folder_path\"|g" {} \;


echo "Setting up dx tools in $folder_path"
echo "Setting up user configuration in $home_dir"
config_file="$folder_path/user_config/config.ini"
echo "Config file: $config_file"

set_value() {
    local key=$1
    local value=$2
    awk -F '=' -v key="$key" -v value="$value" '$1==key {$2=value}1' OFS='=' $config_file > temp && mv temp $config_file
}

set_value "dx_tools_path" "$folder_path"
set_value "dx_user_home" "$home_dir"
set_value "dx_repos_path" "$home_dir/repos"

echo "Default Config file content:"
cat $config_file

echo "Run: $folder_path/dx.sh config init"