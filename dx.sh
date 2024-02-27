#!/bin/bash
home_dir=$(echo ~)
dxtools_path="/opt/dxtools"
user_config_path="$home_dir/.dx"
script_dir=$(dirname "$0")
folder_path="/tmp/repos/dxtools"

# Define some colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

print_error() {
  echo -e "${RED}$1${NC}"
}

print_success() {
  echo -e "${GREEN}$1${NC}"
}

print_info() {
  echo -e "${BLUE}$1${NC}"
}

print_warning() {
  echo -e "${YELLOW}$1${NC}"
}

self_update() {
    print_info "Self updating..."
    if [ -d "$folder_path" ]; then
        print_error "$folder_path exists."

        cd $folder_path
        git checkout develop
        git pull

        # run desired action
    else
        print_error "$folder_path does not exist."
        mkdir -p $folder_path

        cd $folder_path

        git clone https://github.com/deixei/dx.git

    fi

    repo_2_tools

}

repo_2_tools () {
  ## copy content of /tools to /opt/dxtools
  cp -r $folder_path/dx/* $dxtools_path

  ## set permissins to execute all *.sh
  chmod +x $dxtools_path/*.sh
  chmod +x $dxtools_path/scripts/*.sh
}

local_update_2_tools () {
  ## copy content of /tools to $dxtools_path
  cp -r $home_dir/repos/deixei/dx/* $dxtools_path

  ## set permissins to execute all *.sh
  chmod +x $dxtools_path/*.sh
  chmod +x $dxtools_path/scripts/*.sh
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
  echo
  print_info "More:"
  echo "  http://www.deixei.com"

}

me() {
  echo "I am $0"
  echo "I am in $home_dir"
  echo "I am user $(whoami)"
  echo "I am in $(pwd)"
  echo "I am running on $(uname -a)"
  echo "I am using $(bash --version | head -n 1)"
  
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
if [[ -z $command ]]; then
  usage
  exit 1
fi

# Execute the command
case $command in
  config)
    shift
    $script_dir/scripts/config.sh "$@"
    ;;   
  git)
    shift
    $script_dir/scripts/git.sh "$@"
    ;;
  ado)
    shift
    $script_dir/scripts/ado.sh "$@"
    ;;    
  ansible)
    shift
    $script_dir/scripts/ansible.sh "$@"
    ;;
  me)
    me
    ;;
  *)
    print_error "Error: [$command] Unsupported command"
    usage
    exit 1
    ;;
esac