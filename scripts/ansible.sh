#!/bin/bash
subcommand="ansible"
home_dir=$(echo ~)
dxtools_path="/opt/dxtools"
script_dir=$(dirname "$0")
exporting_vars="$home_dir/.dx/exporting_vars.sh"
config_file="$home_dir/.dx/config.ini"
ansible_collections_target_folder="$home_dir/.ansible/collections"
source $script_dir/common.sh

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

build_and_install(){
  local folder=$1

  # check that git is installed
  if ! command -v ansible-galaxy &> /dev/null
  then
      print_error "ansible-galaxy is not installed"
      exit 1
  fi

  temp_dir=$(mktemp -d)
  temp_folder="$temp_dir/tempansible"

  if [ ! -d "$temp_folder" ]; then
      mkdir -p $temp_folder
  fi

  if [ -d "$folder" ]; then

      cd $folder
      ansible-galaxy collection build --force --output-path "$temp_folder"
      
      build_bin_file=$(find $temp_folder -name "*-1.*.tar.gz")
      if [[ -f $build_bin_file ]]; then
          ansible-galaxy collection install "$build_bin_file" --force -p "$ansible_collections_target_folder"
          rm $build_bin_file
      else
          print_error "Error: File not found: $build_bin_file"
      fi
  else
      print_error "This folder [$folder] does not exit."
  fi  
}



search_galaxy_collection(){
  local action=$1  

  find $home_dir -name "galaxy.yml" -exec dirname {} \; | while read -r dir; do
    print_info "Found: $dir"
    if [[ $action == "build" ]]; then
      build_and_install $dir
    fi
  done
}

command_show() {
  print_info "Showing things"
  # load the configuration
  if [[ -f $exporting_vars ]]; then
    source $exporting_vars
  else
    print_error "Configuration file not found: $exporting_vars"
    exit 1
  fi

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
    if [[ -z $command ]]; then
        usage
        exit 1
    fi

    # Execute the command
    case $command in
        track)
          shift
          search_galaxy_collection "show"
          ;;
        build)
          shift
          search_galaxy_collection "build"
          ;;
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

          echo "$name_arg"
          ;;

        *)
            print_error "Error: [$command] Unsupported command"
            usage
            exit 1
            ;;
    esac

}

main "$@"