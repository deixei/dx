#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

subcommand="az"
script_dir=$(dirname "$0")
source "$script_dir/common.sh"
trap 'print_error "Error on line $LINENO."' ERR
command=""
name_arg=""


az_output_arg="json" # default output format: json, yaml, table

ensure_az() {
    if ! command -v az &> /dev/null; then
        print_error "az cli is not installed"
        exit 1
    fi
}

documents() {
    print_warning "### DX Documents - $subcommand ###"
    echo "https://learn.microsoft.com/en-us/cli/azure/reference-docs-index"
}

usage() {
  print_warning "### DX tools - $subcommand ###"
  echo
  print_info "Usage: dx $subcommand [options] [command]"
  echo
  print_info "Options:"
  echo "  -h, --help      Show this help message and exit"
  echo
  print_info "Commands:"

}

command_show() {
  print_info "Showing things"
  # load the configuration
  load_config

  # TODO: Add more
}

cmd_az_login() {
    ensure_az
    az config set core.allow_broker=true
    az account clear
    load_config
    if [[ -z "${AZURE_CLIENT_ID:-}" || -z "${AZURE_SECRET:-}" || -z "${AZURE_TENANT:-}" ]]; then
        print_error "Azure credentials are missing from the configuration"
        exit 1
    fi
    az login --service-principal -u "$AZURE_CLIENT_ID" -p "$AZURE_SECRET" --tenant "$AZURE_TENANT"
}

cmd_az_set_subscription() {
    local subscription_id="$1"

    if [[ -z "$subscription_id" ]]; then
        print_error "Missing subscription ID"
        return 1
    fi
    ensure_az
    az account set --subscription "$subscription_id"
}

cmd_list_subscriptions() {
    ensure_az
    az account list --query "[].{subscription_id:id, name:name, isDefault:isDefault}" -o table
}

cmd_list_resource_groups_by_name() {
    local resource_group_name="$1"
    if [[ -z "$resource_group_name" ]]; then
        print_error "Missing resource group name"
        return 1
    fi

    ensure_az
    az group list --query "[? contains(name, '$resource_group_name')].{ResourceGroupName:name, ResourceGroupId:id}" -o table
}

cmd_search_resource_groups_by_name() {
    local resource_group_name="$1"
    if [[ -z "$resource_group_name" ]]; then
        print_error "Missing resource group name"
        return 1
    fi

    ensure_az
    # Get the list of subscriptions
    local subscriptions
    subscriptions=$(az account list --query "[].{Name:name, Id:id}" --output tsv)
    if [[ -z "$subscriptions" ]]; then
        print_warning "No subscriptions found"
        return 0
    fi

    # Loop over each subscription
    while IFS=$'\t' read -r subscription_name subscription_id; do
        # Set the subscription for the az command
        print_info "Searching in subscription: ${subscription_name}"
        az account set --subscription "${subscription_id}"

        # List the resource groups in the subscription
        az group list --query "[? contains(name, '$resource_group_name')].{ResourceGroupName:name, ResourceGroupId:id, SubscriptionName:'${subscription_name}'}" -o table
    done <<< "$subscriptions"
}

cmd_az_rest() {
    local method="$1"
    local url="$2"
    local body="$3"
    
    if [[ -z "$method" || -z "$url" ]]; then
        print_error "Usage: az rest <method> <url> [body]"
        return 1
    fi
    ensure_az
    # Get the access token
    if ! command -v jq &> /dev/null; then
        print_error "jq is required for az rest"
        return 1
    fi
    local access_token
    access_token=$(az account get-access-token --output json | jq -r .accessToken)

    # Include the access token in the Authorization header
    az rest --method "$method" --uri "$url" --body "$body" --headers "Authorization=Bearer $access_token"

}

get_applications() {
    cmd_az_rest "GET" "https://graph.microsoft.com/v1.0/me" ""
}


main() {
    # Parse command line options
    while [[ $# -gt 0 ]]; do
      case $1 in
        -h|--help)
          usage
          exit 0
          ;;
        -o|--output)
          az_output_arg=$2
          shift
          ;;
        -n|--name)
          name_arg=$2
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
            command_show
            ;;
        login)
            shift
            cmd_az_login
            ;;
        ls)
            shift
            cmd_list_subscriptions
            ;;
        lrg)
          shift
          if [[ -z "$name_arg" ]]; then
              print_error "Error: Missing name argument (--name or -n)"
              exit 1
          fi

          cmd_list_resource_groups_by_name "$name_arg"
          ;;
        searchrg)
          shift
          if [[ -z "$name_arg" ]]; then
              print_error "Error: Missing name argument (--name or -n)"
              exit 1
          fi

          cmd_search_resource_groups_by_name "$name_arg"
          ;;
          apps)
            shift
            get_applications
            ;;
        *)
            print_error "Error: [$command] Unsupported command"
            usage
            exit 1
            ;;
    esac

}

main "$@"
