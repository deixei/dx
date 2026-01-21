#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(dirname "$0")
source "$script_dir/scripts/common.sh"
trap 'print_error "Error on line $LINENO."' ERR

folder_path="/tmp/repos/dxtools"
command=""

self_update() {
    print_info "Self updating..."
    if [ -d "$folder_path" ]; then
        print_error "$folder_path exists."

        cd "$folder_path"
        git checkout develop
        git pull

        # run desired action
    else
        print_error "$folder_path does not exist."
        mkdir -p "$folder_path"

        cd "$folder_path"

        git clone https://github.com/deixei/dx.git

    fi

    repo_2_tools

}

set_chmod() {
  ## set permissions to execute all *.sh
  if ls "$dxtools_path"/*.sh >/dev/null 2>&1; then
    chmod +x "$dxtools_path"/*.sh
  fi
  if ls "$dxtools_path/scripts"/*.sh >/dev/null 2>&1; then
    chmod +x "$dxtools_path/scripts"/*.sh
  fi
  if ls "$dxtools_path/user_config"/*.sh >/dev/null 2>&1; then
    chmod +x "$dxtools_path/user_config"/*.sh
  fi
}

repo_2_tools () {
  ## copy content of /tools to /opt/dxtools
  if [[ ! -d "$folder_path/dx" ]]; then
    print_error "Repository not found in $folder_path/dx"
    return 1
  fi
  cp -r "$folder_path/dx/"* "$dxtools_path"

  set_chmod
}

local_update_2_tools () {
  ## copy content of /tools to $dxtools_path
  if [[ ! -d "$home_dir/repos/deixei/dx" ]]; then
    print_error "Repository not found in $home_dir/repos/deixei/dx"
    return 1
  fi
  cp -r "$home_dir/repos/deixei/dx/"* "$dxtools_path"

  set_chmod
}

usage() {
  print_warning "### DX tools - CLI helper ###"
  echo
  print_info "Usage: $0 [options] [command]"
  echo
  print_info "Options:"
  echo "  -h, --help        Display this help message"
  echo "  -v, --version     Display script version"
  echo "  -u, --update      Self updates the code. Gets the latest version from the repo."
  echo
  print_info "Commands:"
  echo "  config            Config the dxtools (git and azure devops)"
  echo "  git               Git helper"
  echo "  ado               Azure DevOps helper"
  echo "  ansible           Ansible helper"
  echo "  install           Install developer tools"
  echo "  me                Show information about the environment"
  echo "  venv              Virtual environment helper (define virtual env -v, activate -a, deactivate -d)"
  echo "  az                Azure CLI helper"
  echo "  cc                Cookiecutter helper"
  echo
  print_info "More:"
  echo "  http://www.deixei.com"

}

me() {
  print_info "I am $0"
  print_info "I am in $home_dir"
  print_info "I am user $(whoami)"
  print_info "I am in $(pwd)"
  print_info "I am running on $(uname -a)"
  print_info "I am using $(bash --version | head -n 1)"
}

define_virtual_env() {
    print_warning "Defining virtual environment: source ~/bin/dx/activate"
    # check if the virtual environment exists
    if [ ! -f "$home_dir/dx/bin/activate" ]; then
        print_warning "Creating virtual environment"
        python3 -m venv "$home_dir/dx"
    else
        print_warning "Virtual environment already exists"
    fi
  
    source "$home_dir/dx/bin/activate"

    # add to bashrc the source activation if not exists
    touch "$home_dir/.bashrc"
    if ! grep -q "source $home_dir/dx/bin/activate" "$home_dir/.bashrc" 2>/dev/null; then
        print_info "Adding source activation to .bashrc"
        echo "source $home_dir/dx/bin/activate" >> "$home_dir/.bashrc"
    fi
}

activate_virtual_env() {
    print_warning "Activating virtual environment: source ~/bin/dx/activate"
    # if file exists, then activate virtual environment
    if [ -f "$home_dir/dx/bin/activate" ]; then
        source "$home_dir/dx/bin/activate"
    else
        print_error "Virtual environment does not exist"
    fi
}

deactivate_virtual_env() {
    print_warning "Deactivating virtual environment"
    if [[ -n "${VIRTUAL_ENV:-}" ]] && declare -F deactivate >/dev/null; then
      deactivate
    else
      print_error "Virtual environment is not active"
      return 1
    fi
}

# Parse command line options
if [[ $# -gt 0 ]]; then
  case $1 in
    -h|--help)
      usage
      exit 0
      ;;
    -v|--version)
      print_warning "DEIXEI(DX) 1.0.0"
      exit 0
      ;;
    -u|--update)
      self_update
      exit 0
      ;;
    -u1|--update1)
      repo_2_tools
      exit 0
      ;;
    -u2)
      local_update_2_tools
      exit 0
      ;;       
    *)
      command=$1
      ;;
  esac
  
fi

# Check if a command was passed
if [[ -z "$command" ]]; then
  usage
  exit 1
fi

# Execute the command
case "$command" in
  config)
    shift
    "$script_dir/scripts/config.sh" "$@"
    ;;   
  git)
    shift
    "$script_dir/scripts/git.sh" "$@"
    ;;
  ado)
    shift
    "$script_dir/scripts/ado.sh" "$@"
    ;;    
  ansible)
    shift
    "$script_dir/scripts/ansible.sh" "$@"
    ;;
  install)
    shift
    "$script_dir/scripts/install.sh" "$@"
    ;;
  github)
    shift
    "$script_dir/scripts/github.sh" "$@"
    ;;
  me)
    shift
    me
    ;;
  az)
    shift
    "$script_dir/scripts/azcli.sh" "$@"
    ;;
  cc)
    shift
    "$script_dir/scripts/cookiecutter.sh" "$@"
    ;;
  venv)
    shift
      # if flag -v is passed, then define virtual environment
      # if flag -a is passed, then activate virtual environment
      # if flag -d is passed, then deactivate virtual environment
      case $1 in
        -d)
          deactivate_virtual_env
        ;;
        -v)
          define_virtual_env
        ;;
        -a)
          activate_virtual_env
        ;;
        *)
          print_error "Error: [$command] Unsupported command"
          usage
          exit 1
          ;;
      esac
    ;;
  *)
    print_error "Error: [$command] Unsupported command"
    usage
    exit 1
    ;;
esac
