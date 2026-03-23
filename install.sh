#!/bin/bash
set -e  # Exit on error
if [ -n "${ZSH_VERSION-}" ]; then
  setopt PIPE_FAIL
elif [ -n "${BASH_VERSION-}" ]; then
  set -o pipefail
fi
IFS=$'\n\t'

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

log_message() {
    local level="$1"
    local color="$2"
    shift 2
    echo -e "${color}[${level}] $*${NC}"
}

print_error() {
    log_message "ERROR" "$RED" "$@" >&2
}

print_info() {
    log_message "INFO" "$BLUE" "$@"
}

print_warning() {
    log_message "WARN" "$YELLOW" "$@"
}

if [ -n "${ZSH_VERSION-}" ]; then
  trap 'print_error "Error on line $LINENO."' ZERR
else
  trap 'print_error "Error on line $LINENO."' ERR
fi

if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root"
   exit 1
fi
dxtools_path="/opt/dxtools"
script_dir=$(dirname "$0")
# Default values
folder_path="$dxtools_path"
home_dir="${HOME}"

# Parse named parameters
while [[ $# -gt 0 ]]; do
    case $1 in
        --tools_folder)
        if [[ -z "${2:-}" ]]; then
          print_error "Missing value for --tools_folder"
          exit 1
        fi
        folder_path=$2
        shift
        ;;
        --user_path)
        if [[ -z "${2:-}" ]]; then
          print_error "Missing value for --user_path"
          exit 1
        fi
        home_dir=$2
        shift
        ;;
    esac
    shift
done

# Copying the scripts to the desired folder
mkdir -p "$folder_path"
cp -r "$script_dir/"* "$folder_path"
if ls "$folder_path"/*.sh >/dev/null 2>&1; then
  chmod +x "$folder_path"/*.sh
fi
if ls "$folder_path/scripts"/*.sh >/dev/null 2>&1; then
  chmod +x "$folder_path/scripts"/*.sh
fi

find "$folder_path/." -type f -name "*.sh" -exec sed -i "s|dxtools_path=\"/opt/dxtools\"|dxtools_path=\"$folder_path\"|g" {} \;


print_info "Setting up dx tools in $folder_path"
print_info "Setting up user configuration in $home_dir"
config_file="$folder_path/user_config/config.ini"
print_info "Config file: $config_file"

set_value() {
    local key=$1
    local value=$2
    local tmp_file
    tmp_file=$(mktemp)
    awk -F '=' -v key="$key" -v value="$value" '$1==key {$2=value}1' OFS='=' "$config_file" > "$tmp_file"
    mv "$tmp_file" "$config_file"
}

set_value "dx_tools_path" "$folder_path"
set_value "dx_user_home" "$home_dir"
set_value "dx_repos_path" "$home_dir/repos"

print_info "Default Config file content:"
cat "$config_file"

print_info "Run: $folder_path/dx.sh config init"
