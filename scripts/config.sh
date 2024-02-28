#!/bin/bash
home_dir=$(echo ~)
dxtools_path="/opt/dxtools"

script_dir=$(dirname "$0")
exporting_vars="$home_dir/.dx/exporting_vars.sh"
config_file="$home_dir/.dx/config.ini"
source $script_dir/common.sh

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
  cat $home_dir/.dx/config.ini
}

cat_local_config() {
  print_info "Configuration file: $script_dir/.dx/config.ini"
  cat $config_file
}

set_bashrc() {
  alias dx=$dxtools_path/dx.sh

  if grep -q "alias dx=" ~/.bashrc; then
    print_error "Alias DX already exists"
  else
    echo "alias dx='$dxtools_path/dx.sh'" >> ~/.bashrc
  fi

  if grep -q "if [[ -f ~/.dx/exporting_vars.sh ]]; then" ~/.bashrc; then
    print_info "Configuration already exists"
  else
    echo "if [[ -f ~/.dx/exporting_vars.sh ]]; then" >> ~/.bashrc
    echo "    . ~/.dx/exporting_vars.sh" >> ~/.bashrc
    echo "fi" >> ~/.bashrc
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
    while IFS= read -r line
    do
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

      # If the flag is true, display the value
      if [[ "$display_values" == "true" ]]; then
        echo "$var_name: '$value'"
      fi

      # Export the variable
      export $var_name=$value
    done < <(cat "$config_file"; echo)
}

# Function to get a value from the config.ini file
get_value() {
    local key=$1
    awk -F '=' -v key="$key" '$1==key {print $2}' $config_file
}

# Function to set a value in the config.ini file
set_value() {
    local key=$1
    local value=$2
    awk -F '=' -v key="$key" -v value="$value" '$1==key {$2=value}1' OFS='=' $config_file > temp && mv temp $config_file
}

# Function to delete a key-value pair from the config.ini file
delete_key() {
    local key=$1
    awk -F '=' -v key="$key" '$1!=key' config.ini > temp && mv temp $config_file
}

init() {
    echo "Creating configuration file: $config_file"
    mkdir -p $home_dir/.dx
    cp -r $dxtools_path/user_config/* $home_dir/.dx
    chmod +x $home_dir/.dx/*.sh
}

write_config_setting() {
  local key="$1"
  local value="$2"

  # Check if the file exists
  if [[ ! -f "$config_file" ]]; then
    echo "Configuration file not found: $config_file"
    init
  fi

  current_value=$(get_value "$key")

  if [[ -z "$current_value" ]]; then
    echo "Setting $key=$value"
    echo "$key=$value" >> $config_file
  else
    echo "Updating $key=$value"
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

  echo "tenant: $tenant"
  echo "client: $client"
  echo "secret: $secret"

  az login --service-principal -u $client -p $secret --tenant $tenant

}

generate_service_principal() {
    # Replace with your own values
    # TODO: bug this needs to be unique per user
    local name="$1"

    SERVICE_PRINCIPAL_NAME="dx_${name}_sp"

    # Create the service principal with the Owner role and capture the output as JSON
    SP_OUTPUT=$(az ad sp create-for-rbac --name "$SERVICE_PRINCIPAL_NAME" --role Owner --sdk-auth)

    # Extract the values from the output JSON and store them in variables
    APP_ID=$(echo "$SP_OUTPUT" | grep -oP '(?<="clientId": ")[^"]+')
    TENANT_ID=$(echo "$SP_OUTPUT" | grep -oP '(?<="tenantId": ")[^"]+')
    CLIENT_SECRET=$(echo "$SP_OUTPUT" | grep -oP '(?<="clientSecret": ")[^"]+')


    # Print the values for verification
    echo "$APP_ID"
    echo "$CLIENT_SECRET"
    echo "$TENANT_ID"

    write_config_setting "${name}azure_tenant" "$TENANT_ID"
    write_config_setting "${name}azure_client_id" "$APP_ID"
    write_config_setting "${name}azure_client_secret" "$CLIENT_SECRET"

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
        *)
          command=$1
          ;;
      esac
      shift
    done

    # Check if a command was passed
    if [[ -z $command ]]; then
        usage
        exit 1
    fi

    # Execute the command
    case $command in
        show)
          shift
          print_info "Default configurations"
          cat_local_config
          echo
          print_info "User configurations"
          cat_config

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

          generate_service_principal "$name_arg"
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
            if [[ -f $exporting_vars ]]; then
              source $exporting_vars

              #read_init_config false
            else
              print_error "Configuration file not found: $exporting_vars"
              exit 1
            fi

            if [[ -z "$tenant_arg" ]]; then
              if [[ -z "$AZURE_TENANT" ]]; then
                  print_error "Error: Missing azure_tenant in configuration file"
                  exit 1
              fi
            else
                # update the git name in configuration file
                write_config_setting "azure_tenant" "$tenant_arg"
                AZURE_TENANT=$tenant_arg
            fi

            if [[ -z "$client_arg" ]]; then
              if [[ -z "$AZURE_CLIENT_ID" ]]; then
                  print_error "Error: Missing azure_client_id in configuration file"
                  exit 1
              fi
            else
                # update the git email in configuration file
                write_config_setting "azure_client_id" "$client_arg"
                AZURE_CLIENT_ID=$client_arg
            fi

            if [[ -z "$secret_arg" ]]; then
              if [[ -z "$AZURE_CLIENT_SECRET" ]]; then
                  print_error "Error: Missing azure_client_secret in configuration file"
                  exit 1
              fi
            else
                # update the git email in configuration file
                write_config_setting "azure_client_secret" "$secret_arg"
                AZURE_CLIENT_SECRET=$secret_arg
            fi

            az_config "$AZURE_TENANT" "$AZURE_CLIENT_ID" "$AZURE_CLIENT_SECRET"
            ;;
        git)
            shift

            if [[ -f $exporting_vars ]]; then
              source $exporting_vars
            else
              print_error "Configuration file not found: $exporting_vars"
              exit 1
            fi

            if [[ -z "$name_arg" ]]; then
              if [[ -z "$GIT_NAME" ]]; then
                  print_error "Error: Missing git_name in configuration file"
                  exit 1
              fi
            else
                # update the git name in configuration file
                write_config_setting "git_name" "$name_arg"
                GIT_NAME=$name_arg
            fi
            echo "GIT_NAME: $GIT_NAME"

            if [[ -z "$email_arg" ]]; then
              if [[ -z "$GIT_EMAIL" ]]; then
                  print_error "Error: Missing git_email in configuration file"
                  exit 1
              fi
            else
                # update the git email in configuration file
                write_config_setting "git_email" "$email_arg"
                GIT_EMAIL=$email_arg
            fi
            echo "GIT_EMAIL: $GIT_EMAIL"


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