#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

subcommand="ado"

script_dir=$(dirname "$0")
source "$script_dir/common.sh"
trap 'print_error "Error on line $LINENO."' ERR
command=""
name_arg=""

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

cmd_list_repos(){
  local project_name="$1"
  if [[ -z "$project_name" ]]; then
    print_error "Error: Missing project name"
    return 1
  fi
  if ! command -v az &> /dev/null; then
    print_error "az cli is not installed"
    return 1
  fi
  print_warning "Get repos from project: $project_name"
  while IFS= read -r name; do
    print_info "Repository name: $name"
  done < <(az repos list --project "$project_name" --query "[].name" -o tsv)
}

command_show() {
  print_info "Showing things"
  # load the configuration
  load_config

  # TODO: Add more
}

main() {
    # Parse command line options
    while [[ $# -gt 0 ]]; do
      case $1 in
        -h|--help)
          usage
          exit 0
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

        new)
          shift
          if [[ -z "$name_arg" ]]; then
              print_error "Error: Missing name argument (--name or -n)"
              exit 1
          fi

          print_info "$name_arg"
          ;;

        *)
            print_error "Error: [$command] Unsupported command"
            usage
            exit 1
            ;;
    esac

}

main "$@"
