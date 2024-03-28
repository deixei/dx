#!/bin/bash
subcommand="cc"
script_dir=$(dirname "$0")
source $script_dir/common.sh

usage() {
  print_warning "### DX tools - $subcommand ###"
  echo
  print_info "Usage: dx $subcommand [options] [command]"
  echo
  echo "https://cookiecutter.readthedocs.io/en/2.0.2/index.html"
  echo
  print_info "Options:"
  echo "  -h, --help      Show this help message and exit"
  echo "  -n, --name      Name of the template"
  echo "  -i, --input     Input file"
  echo
  print_info "Commands:"
  echo
  echo "  show                                Show information"
  echo "  init -n <name> -i user_config.yaml  Initialize a new template"
  echo
  print_info "Examples:"
  echo
  echo " dx cc init -n simple -i user_config.yaml"

}

# cookiecutter https://github.com/user/repo-name.git --directory="directory1-name"
# cookiecutter https://github.com/deixei/cookie.git --directory="simple"

command_run() {
  local directory_name=$1
  local input_file=$2
  print_info "Running cookiecutter"
  # load the configuration
  load_config

    # check that cookiecutter is installed
    if ! command -v cookiecutter &> /dev/null
    then
        print_info "cookiecutter is not installed. Run: dx install cookiecutter"
    else
      # if no input file is provided
      if [[ -z "$input_file" ]]; then
        cookiecutter https://github.com/deixei/cookie.git --directory="$directory_name"
      else

        # if input file exists
        if [ ! -f "$input_file" ]; then
          print_error "Error: Input file not found: $input_file"
          exit 1
        fi

        cookiecutter https://github.com/deixei/cookie.git --directory="$directory_name" --no-input --config-file "$input_file"
      fi
      
    fi

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
        -i|--input)
          input_arg=$2
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
          command_show
          ;;
        init)
          shift
          if [[ -z "$name_arg" ]]; then
              print_error "Error: Missing name argument (--name or -n)"
              exit 1
          fi

          command_run "$name_arg" "$input_arg"
          ;;

        *)
            print_error "Error: [$command] Unsupported command"
            usage
            exit 1
            ;;
    esac

}

main "$@"