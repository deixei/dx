#!/bin/bash
home_dir=$(echo ~)
dxtools_path="/opt/dxtools"
user_config_path="$home_dir/.dx"
exporting_vars="$home_dir/.dx/exporting_vars.sh"
config_file="$home_dir/.dx/config.ini"

# Define some colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

print_error() {
  echo -e "${RED}$1${NC}"
}

print_success() {
  echo -e "${GREEN}$1${NC}"
}

print_info() {
  echo -e "${BLUE}$1${NC}"
}

print_warning() {
  echo -e "${YELLOW}$1${NC}"
}

load_config() {
  if [[ -f $exporting_vars ]]; then
    source $exporting_vars
  else
    print_error "Configuration file not found: $exporting_vars"
    exit 1
  fi
}