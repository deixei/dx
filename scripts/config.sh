#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(dirname "$0")
source "$script_dir/common.sh"
trap 'print_error "Error on line $LINENO."' ERR
command=""
key_arg=""
value_arg=""
name_arg=""
email_arg=""
tenant_arg=""
client_arg=""
secret_arg=""
output_arg=""

usage() {
  print_warning "### DX tools - CONFIG - CLI helper ###"
  echo
  print_info "Usage: $0 [options] [command]"
  echo
  print_info "Options:"
  echo "  -h, --help      Show this help message and exit"
  echo "  -s, --show      Show the current configuration"
  echo "  -k, --key       The key to set"
  echo "  -v, --value     The value to set"
  echo
  print_info "Commands:"
  echo "  init            Create the user configuration file"
  echo "  show            Show the default and current user configuration"
  echo "  set             Set a configuration value. --key and --value are required"
  echo "  az              Set Azure DevOps configurations. To override the configuration file use --tenant, --client, --secret"
  echo "  git             Git configurations. To override the configuration file use --name, --email"
  echo
  print_info "Examples:"
  echo "  dx config init"
  echo "  dx config show"
  echo "  dx config set --key git_name --value 'John Doe'"
  echo "  dx config az --tenant <tenant> --client <client> --secret <secret>"
  echo "  dx config git --name 'John Doe' --email deixei@deixei.com "
  echo
  print_info "Configuration file: $config_file"
  echo
  echo " source ~/.dx/exporting_vars.sh"

}

cat_config() {
  print_info "Configuration file: $home_dir/.dx/config.ini"
  cat "$home_dir/.dx/config.ini"
}

cat_local_config() {
  print_info "Configuration file: $script_dir/.dx/config.ini"
  cat "$config_file"
}

set_bashrc() {
  local bashrc_file="$home_dir/.bashrc"
  touch "$bashrc_file"
  alias dx="$dxtools_path/dx.sh"

  if grep -q '^alias dx=' "$bashrc_file" 2>/dev/null; then
    print_error "Alias DX already exists"
  else
    echo "alias dx='$dxtools_path/dx.sh'" >> "$bashrc_file"
  fi

  local export_line
  local source_line
  export_line="if [[ -f \"$home_dir/.dx/exporting_vars.sh\" ]]; then"
  source_line="    . \"$home_dir/.dx/exporting_vars.sh\""
  if grep -Fq "$export_line" "$bashrc_file" 2>/dev/null; then
    print_info "Configuration already exists"
  else
    echo "$export_line" >> "$bashrc_file"
    echo "$source_line" >> "$bashrc_file"
    echo "fi" >> "$bashrc_file"
  fi
}

# Read the configuration file
# ignore empty lines and lines starting with #
read_init_config() {
    # The first argument to the function is the display_values flag
    local display_values="$1"

    # check if the file exists
    if [[ ! -f "$config_file" ]]; then
      print_error "Configuration file not found: $config_file"
      return 1
    fi
    if [[ "$display_values" == "true" ]]; then
      print_info "Configuration file: $config_file"
    fi

    # Read the configuration file line by line
    while IFS= read -r line; do
      # Ignore empty lines and lines starting with #
      if [[ -z "$line" || ${line:0:1} == "#" ]]; then
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
          echo "$var_name=$value"
        fi

        # Export the variable
        export "${var_name}=${value}"
      else
        print_warning "Skipping invalid config key: $var_name"
      fi
    done < <(cat "$config_file"; echo)
}

# Function to get a value from the config.ini file
get_value() {
    local key=$1
    awk -F '=' -v key="$key" '$1==key {print $2}' "$config_file"
}

# Function to set a value in the config.ini file
set_value() {
    local key=$1
    local value=$2
    local tmp_file
    tmp_file=$(mktemp)
    awk -F '=' -v key="$key" -v value="$value" '$1==key {$2=value}1' OFS='=' "$config_file" > "$tmp_file"
    mv "$tmp_file" "$config_file"
}

# Function to delete a key-value pair from the config.ini file
delete_key() {
    local key=$1
    local tmp_file
    tmp_file=$(mktemp)
    awk -F '=' -v key="$key" '$1!=key' "$config_file" > "$tmp_file"
    mv "$tmp_file" "$config_file"
}

init() {
    print_info "Creating configuration file: $config_file"
    mkdir -p "$home_dir/.dx"
    cp -r "$dxtools_path/user_config/"* "$home_dir/.dx"
    if ls "$home_dir/.dx/"*.sh >/dev/null 2>&1; then
      chmod +x "$home_dir/.dx/"*.sh
    fi
}

write_config_setting() {
  local key="$1"
  local value="$2"

  # Check if the file exists
  if [[ ! -f "$config_file" ]]; then
    print_error "Configuration file not found: $config_file"
    init
  fi

  local current_value
  current_value=$(get_value "$key")

  if [[ -z "$current_value" ]]; then
    print_info "Setting $key=$value"
    echo "$key=$value" >> "$config_file"
  else
    print_info "Updating $key=$value"
    set_value "$key" "$value"
  fi
}

git_config() {
  local name="$1"
  local email="$2"

  # check that git is installed
  if ! command -v git &> /dev/null
  then
      print_error "Git is not installed"
      exit 1
  fi
  print_info "Executing git config --global ..."
  git config --global user.name "$name"
  git config --global user.email "$email"
}

az_config() {
  local tenant="$1"
  local client="$2"
  local secret="$3"

  if ! command -v az &> /dev/null
  then
      print_error "az cli is not installed"
      exit 1
  fi

  print_info "tenant: $tenant"
  print_info "client: $client"
  print_info "secret: $secret"

  az login --service-principal -u "$client" -p "$secret" --tenant "$tenant"

}

generate_service_principal() {
    # Replace with your own values
    # TODO: bug this needs to be unique per user
    # https://learn.microsoft.com/en-us/cli/azure/azure-cli-sp-tutorial-1?tabs=bash
    # https://learn.microsoft.com/en-us/azure/role-based-access-control/scope-overview

    local name="$1"
    local management_group="$2"
    if [[ -z "$name" || -z "$management_group" ]]; then
      print_error "Service principal name and management group are required"
      return 1
    fi

    local service_principal_name="dx_${name}_sp"

    # Create the service principal with the Owner role and capture the output as JSON
    local sp_output
    sp_output=$(az ad sp create-for-rbac --name "$service_principal_name" --role Owner --scope "/providers/Microsoft.Management/managementGroups/$management_group")

    print_warning "Service principal output:"
    echo "$sp_output"

    # Extract the values from the output JSON and store them in variables
    local app_id
    local tenant_id
    local client_secret
    app_id=$(echo "$sp_output" | grep -oP '(?<="appId": ")[^"]+')
    tenant_id=$(echo "$sp_output" | grep -oP '(?<="tenant": ")[^"]+')
    client_secret=$(echo "$sp_output" | grep -oP '(?<="password": ")[^"]+')

    print_warning "Service principal values:"
    # Print the values for verification
    echo "$app_id"
    echo "$client_secret"
    echo "$tenant_id"

    write_config_setting "azure_tenant" "$tenant_id"
    write_config_setting "azure_client_id" "$app_id"
    write_config_setting "azure_secret" "$client_secret"

    write_config_setting "${service_principal_name}_azure_tenant" "$tenant_id"
    write_config_setting "${service_principal_name}_azure_client_id" "$app_id"
    write_config_setting "${service_principal_name}_azure_secret" "$client_secret"
    

    print_info "Service principal created and saved in configuration file"
    echo "  dx config az --tenant \"$tenant_id\" --client \"$app_id\" --secret \"$client_secret\""
    echo "  dx config show"

}

main() {
    # Parse command line options
    while [[ $# -gt 0 ]]; do
      case $1 in
        -h|--help)
          usage
          exit 0
          ;;
        -s|--show)
          read_init_config true
          exit 0
          ;;
        -k|--key)
          key_arg=$2
          shift
          ;;
        -v|--value)
          value_arg=$2
          shift
          ;;
        -n|--name)
          name_arg=$2
          shift
          ;;
        -e|--email)
          email_arg=$2
          shift
          ;;
        -t|--tenant)
          tenant_arg=$2
          shift
          ;;
        -c|--client)
          client_arg=$2
          shift
          ;;
        -s|--secret)
          secret_arg=$2
          shift
          ;;
        -o|--output)
          output_arg=$2
          shift
          ;;          
        *)
          command=$1
          ;;
      esac
      shift
    done

    # Check if a command was passed
    if [[ -z "$command" ]]; then
        usage
        exit 1
    fi

    # Execute the command
    case "$command" in
        show)
          shift

          if [[ -z "$output_arg" ]]; then
            print_info "Default configurations"
            cat_local_config
            echo
            print_info "User configurations"
            cat_config

            exit 0
          fi

          if [[ "$output_arg" == "local" ]]; then
            print_warning "Local configurations"
            cat_local_config
          fi

          if [[ "$output_arg" == "user" ]]; then
            print_warning "User configurations"
            cat_config
          fi

          if [[ "$output_arg" == "env" ]]; then
            print_warning "Environment variables"
            read_init_config true
            echo "PYTHONPATH=~/.ansible/collections/ansible_collections"
          fi

          ;;
        init)
          shift
          init

          cat_config

          set_bashrc
          ;;
        sp)
          shift
          if [[ -z "$name_arg" ]]; then
              print_error "Error: Missing name argument (--name or -n)"
              exit 1
          fi

          if [[ -z "$key_arg" ]]; then
              print_error "Error: Missing key argument (--key or -k). With Management Group ID"
              exit 1
          fi

          generate_service_principal "$name_arg" "$key_arg"
          ;;
        set)
          shift
          if [[ -z "$key_arg" ]]; then
              print_error "Error: Missing key argument (--key or -k)"
              exit 1
          fi
          if [[ -z "$value_arg" ]]; then
              print_error "Error: Missing value argument (--value or -v)"
              exit 1
          fi

          write_config_setting "$key_arg" "$value_arg"

          cat_config
          ;;
        az)
            shift
            # load the configuration
            load_config

            if [[ -z "$tenant_arg" ]]; then
              if [[ -z "${AZURE_TENANT:-}" ]]; then
                  print_error "Error: Missing azure_tenant in configuration file"
                  exit 1
              fi
            else
                # update the git name in configuration file
                write_config_setting "azure_tenant" "$tenant_arg"
                AZURE_TENANT=$tenant_arg
            fi

            if [[ -z "$client_arg" ]]; then
              if [[ -z "${AZURE_CLIENT_ID:-}" ]]; then
                  print_error "Error: Missing azure_client_id in configuration file"
                  exit 1
              fi
            else
                # update the git email in configuration file
                write_config_setting "azure_client_id" "$client_arg"
                AZURE_CLIENT_ID=$client_arg
            fi

            if [[ -z "$secret_arg" ]]; then
              if [[ -z "${AZURE_SECRET:-}" ]]; then
                  print_error "Error: Missing azure_secret in configuration file"
                  exit 1
              fi
            else
                # update the git email in configuration file
                write_config_setting "azure_secret" "$secret_arg"
                AZURE_SECRET=$secret_arg
            fi

            az_config "$AZURE_TENANT" "$AZURE_CLIENT_ID" "$AZURE_SECRET"
            ;;
        git)
            shift

            load_config

            if [[ -z "$name_arg" ]]; then
              if [[ -z "${GIT_NAME:-}" ]]; then
                  print_error "Error: Missing git_name in configuration file"
                  exit 1
              fi
            else
                # update the git name in configuration file
                write_config_setting "git_name" "$name_arg"
                GIT_NAME=$name_arg
            fi
            print_info "GIT_NAME: $GIT_NAME"

            if [[ -z "$email_arg" ]]; then
              if [[ -z "${GIT_EMAIL:-}" ]]; then
                  print_error "Error: Missing git_email in configuration file"
                  exit 1
              fi
            else
                # update the git email in configuration file
                write_config_setting "git_email" "$email_arg"
                GIT_EMAIL=$email_arg
            fi
            print_info "GIT_EMAIL: $GIT_EMAIL"


            git_config "$GIT_NAME" "$GIT_EMAIL"
            ;;


        *)
            print_error "Error: [$command] Unsupported command"
            usage
            exit 1
            ;;
    esac

}

main "$@"
