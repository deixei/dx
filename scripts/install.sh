#!/bin/bash
subcommand="install"

script_dir=$(dirname "$0")
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
    echo "  show            Show information"
    echo "  python          Install python"
    echo "  ansible         Install ansible"
    echo "  devtools       Install developer tools"


}

command_show() {
    print_info "Showing things"
    # load the configuration
    load_config

    # TODO: Add more

    print_info "DX tools path: $dxtools_path"
    echo "--------------------------------------"
    show_python_version
    echo "--------------------------------------"
    print_info "Ansible version: $(ansible --version)"
    echo "--------------------------------------"
    print_info "Azure CLI version: $(az --version)"
}

install_python() {
    print_warning "Installing python"
    apt update
    apt install -y python3 python3-pip
    apt install -y python3-venv
}

show_python_version() {
    print_info "Python version: $(python3 --version)"
    print_info "Pip version: $(pip3 --version)"
}

install_ansible() {
    print_warning "Installing ansible"

    # check that python3 and python3 -m pip -V are installed
    if ! command -v python3 &> /dev/null
    then
        print_error "python3 is not installed. Run: dx install python"
        exit 1
    fi

    if ! command -v pip3 &> /dev/null
    then
        print_error "pip3 is not installed. Run: dx install python"
        exit 1
    fi
    
    if [[ $EUID -ne 0 ]]; then
        #This script must be run as root
        python3 -m pip install ansible
        export PATH=$PATH:/root/.local/bin
    else
        python3 -m pip install --user ansible
        # add to PATH export PATH=$PATH:/home/marcio/.local/bin
        export PATH=$PATH:$home_dir/.local/bin
    fi

}


install_developer_tools() {
    print_warning "Installing developer tools"

    # check that git is installed
    if ! command -v git &> /dev/null
    then
        print_info "git is not installed"
        app install -y git
    else
        print_success "git is installed"
    fi

    # check that python3 and python3 -m pip -V are installed
    if ! command -v python3 &> /dev/null
    then
        print_error "python3 is not installed. Run: dx install python"
        exit 1
    else
        print_success "python3 is installed"
    fi

    if ! command -v pip3 &> /dev/null
    then
        print_error "pip3 is not installed. Run: dx install python"
        exit 1
    else
        print_success "pip3 is installed"
    fi

    # check that ansible is installed
    if ! command -v ansible &> /dev/null
    then
        print_error "ansible is not installed. Run: dx install ansible"
        exit 1
    else
        print_success "ansible is installed"
    fi

    print_warning "Installing python requirements"
    python3 -m pip install -r $script_dir/requirements.txt

    # check that ansible-galaxy is installed
    if ! command -v ansible-galaxy &> /dev/null
    then
        print_error "ansible-galaxy is not installed"
        exit 1
    else
        print_success "ansible-galaxy is installed"
    fi

    # check and instal jq
    if ! command -v jq &> /dev/null
    then
        print_info "jq is not installed"
        app install -y jq
    else
        print_success "jq is installed"
    fi

    # check and install yq
    if ! command -v yq &> /dev/null
    then
        print_info "yq is not installed"
        app install -y yq
    else
        print_success "yq is installed"
    fi

    # check and install azure-cli
    if ! command -v az &> /dev/null
    then
        print_info "az is not installed"
        app install -y azure-cli
    else
        print_success "az is installed"
    fi

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
        show)
          shift
          command_show

          ;;
        python)
          shift
          install_python
          ;;
        ansible)
            shift
            install_ansible
            ;;
        devtools)
            shift
            install_developer_tools
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