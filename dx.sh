#!/bin/bash
home_dir=$(echo ~)
dxtools_path="/opt/dxtools"


folder_path="/tmp/repos/dxtools"

self_update() {
    echo "Self updating..."
    if [ -d "$folder_path" ]; then
        echo "$folder_path exists."

        cd $folder_path
        git checkout develop
        git pull

        # run desired action
    else
        echo "$folder_path does not exist."
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
  echo "### DX tools - CLI helper ###"
  echo
  echo "Usage: $0 [options] [command]"
  echo
  echo "Options:"
  echo "  -h, --help        Display this help message"
  echo "  -v, --version     Display script version"
  echo "  -u, --update      Self updates the code. Gets the latest version from the repo."
  echo
  echo "Commands:"
  echo "  config            Config the dxtools (git and azure devops)"
  echo "  azconfig          Config Azure service principle "
}

# Parse command line options
if [[ $# -gt 0 ]]; then
  case $1 in
    -h|--help)
      usage
      exit 0
      ;;
    -v|--version)
      echo "DEIXEI(DX) 1.0.0"
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
    $dxtools_path/scripts/config.sh "$@"
    ;;   
  git)
    shift
    $dxtools_path/scripts/git.sh "$@"
    ;;
  ado)
    shift
    $dxtools_path/scripts/ado.sh "$@"
    ;;    
  ansible)
    shift
    $dxtools_path/scripts/ansible.sh "$@"
    ;;
  *)
    echo "Error: [$command] Unsupported command"
    usage
    exit 1
    ;;
esac