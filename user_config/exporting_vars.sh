#!/bin/bash
# Avoid enforcing strict mode when sourced to prevent impacting the parent shell.
_running_directly=false
if [ -n "${BASH_VERSION-}" ]; then
  [ "${BASH_SOURCE[0]}" = "$0" ] && _running_directly=true
elif [ -n "${ZSH_VERSION-}" ]; then
  case "$ZSH_EVAL_CONTEXT" in *:file) ;; *) _running_directly=true ;; esac
fi
if [ "$_running_directly" = true ]; then
  set -e  # Exit on error
  if [ -n "${ZSH_VERSION-}" ]; then
    setopt PIPE_FAIL
  elif [ -n "${BASH_VERSION-}" ]; then
    set -o pipefail
  fi
  IFS=$'\n\t'
fi
unset _running_directly

# TO use it: 
# source ~/.dx/exporting_vars.sh 
# echo $DX_TOOLS_PATH

home_dir="${HOME}"
dxtools_path="/opt/dxtools"
if [ -n "${BASH_VERSION-}" ]; then
  script_dir=$(dirname "${BASH_SOURCE[0]}")
else
  script_dir=$(dirname "$0")
fi
# Read the configuration file
# ignore empty lines and lines starting with #
# Extract sections and configurations
# make an export in upper case the Section_Configuration=value
# Example: [General] -> GENERAL_...
# Example: [Git] -> GIT_...
read_init_config() {
    # The first argument to the function is the display_values flag
    local display_values="$1"
    

    config_file="$script_dir/config.ini"

    if [[ ! -f "$config_file" ]]; then
      echo "Configuration file not found: $config_file"
      return 1
    fi


    # Read the configuration file line by line
    while IFS= read -r line; do
      # Ignore empty lines and lines starting with #
      if [[ -z "$line" || ${line:0:1} == "#" ]]; then
        continue
      fi

      # Check if the line is a section
      if [[ ${line:0:1} == "[" && ${line: -1} == "]" ]]; then
        continue
      fi

      # Extract the configuration key and value
      key=$(echo "$line" | awk -F'=' '{gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}')
      value=$(echo "$line" | awk -F'=' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')

      # Construct the export variable name
      var_name="${key}"
      var_name=$(echo "$var_name" | tr '[:lower:]' '[:upper:]')
      
      if [[ "$var_name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        # If the flag is true, display the value
        if [[ "$display_values" == "true" ]]; then
          echo "export $var_name=$value"
        fi

        # Export the variable
        export "${var_name}=${value}"
      else
        echo "Skipping invalid config key: $var_name" >&2
      fi
    done < <(cat "$config_file"; echo)
}

if [[ $# -gt 0 ]]; then
  case $1 in
    -s|--show)
      read_init_config true
      exit 0
      ;;
  esac
fi
#echo "Exporting variables from $script_dir/config.ini"
read_init_config false
