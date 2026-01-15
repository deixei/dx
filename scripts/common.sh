#!/bin/bash
home_dir="${HOME}"
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

log_message() {
  local level="$1"
  local color="$2"
  shift 2
  echo -e "${color}[${level}] $*${NC}"
}

print_error() {
  log_message "ERROR" "$RED" "$@" >&2
}

print_success() {
  log_message "SUCCESS" "$GREEN" "$@"
}

print_info() {
  log_message "INFO" "$BLUE" "$@"
}

print_warning() {
  log_message "WARN" "$YELLOW" "$@"
}

load_config() {
  if [[ -f "$exporting_vars" ]]; then
    source "$exporting_vars"
  else
    print_error "Configuration file not found: $exporting_vars"
    exit 1
  fi
}
