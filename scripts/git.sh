#!/bin/bash
set -e  # Exit on error
if [ -n "${ZSH_VERSION-}" ]; then
  setopt PIPE_FAIL
elif [ -n "${BASH_VERSION-}" ]; then
  set -o pipefail
fi
IFS=$'\n\t'

subcommand="git"
script_dir=$(dirname "$0")
source "$script_dir/common.sh"
if [ -n "${ZSH_VERSION-}" ]; then
  trap 'print_error "Error on line $LINENO."' ZERR
else
  trap 'print_error "Error on line $LINENO."' ERR
fi
command=""
name_arg=""
project_arg=""
repo_arg=""
url_arg=""

usage() {
  print_warning "### DX tools - $subcommand ###"
  echo
  print_info "Usage: dx $subcommand [options] [command]"
  echo
  print_info "Options:"
  echo "  -h, --help      Show this help message and exit"
  echo "  -n, --name      The name of the project"
  echo "  -p, --project   The name of the project"
  echo "  -r, --repo      The name of the repository"
  echo "  -u, --url       The url of the repository"
  echo
  print_info "Commands:"
  echo
  echo " clone -u [url]          Clone a git repository"
  echo
  print_info "Examples:"
  echo
  echo " dx git clone -u https://github.com/deixei/cookie.git       # Clone a github repository, under repos/deixei/cookie"

}

command_show() {
  print_info "Showing things"
  # load the configuration
  load_config

  # TODO: Add more
}


command_git_clone() {

  local repo_url="${1:-}"
  local project_name="${2:-}"
  local repo_name="${3:-}"

  if [[ -z "$repo_url" || -z "$project_name" || -z "$repo_name" ]]; then
    print_error "Missing repository details"
    return 1
  fi
  if ! command -v git &> /dev/null; then
    print_error "Git is not installed"
    return 1
  fi

  local base_folder="$home_dir/repos/$project_name"

  if [ ! -d "$base_folder" ]; then
      mkdir -p "$base_folder"
  fi

  local folder="$base_folder/$repo_name"
  print_warning "Running: [git clone $repo_url] into folder: [$folder]."

  if [ ! -d "$folder" ]; then
    git clone "$repo_url" "$folder"
  else
    print_info "The $folder folder already exists."
  fi
}

cmd_github_clone() {
  local repo_url="${1:-}"
  if [[ -z "$repo_url" ]]; then
    print_error "Missing repository URL"
    return 1
  fi
  # parse the repo url similar to https://github.com/deixei/factory.git into project_name and repo_name
  # project_name=deixei
  # repo_name=factory
  local project_name
  local repo_name
  project_name=$(awk -F'/' '{print $4}' <<< "$repo_url")
  repo_name=$(awk -F'/' '{print $5}' <<< "$repo_url" | awk -F'.' '{print $1}')

  print_info "Project name: $project_name"
  print_info "Repo name: $repo_name"
  print_info "Url: $repo_url"

  command_git_clone "$repo_url" "$project_name" "$repo_name"
}

cmd_azure_clone(){
  local repo_url="${1:-}"
  if [[ -z "$repo_url" ]]; then
    print_error "Missing repository URL"
    return 1
  fi

  local project_name
  local repo_name
  project_name=$(awk -F'/' '{print $6}' <<< "$repo_url")
  repo_name=$(awk -F'/' '{print $8}' <<< "$repo_url")

  print_info "Project name: $project_name"
  print_info "Repo name: $repo_name"
  print_info "Url: $repo_url"

  command_git_clone "$repo_url" "$project_name" "$repo_name"
}

generate_ado_repo_url(){
  local project_name=$1
  local repo_name=$2

  # load the configuration
  load_config

  if [[ -z "$project_name" || -z "$repo_name" ]]; then
    print_error "Project and repo names are required"
    return 1
  fi
  if [[ -z "${DX_ADO_URL:-}" ]]; then
    print_error "DX_ADO_URL is not configured"
    return 1
  fi
  echo "$DX_ADO_URL/$project_name/$repo_name/_git/$repo_name"
}

generate_github_repo_url(){
  local project_name=$1
  local repo_name=$2

  if [[ -z "$project_name" || -z "$repo_name" ]]; then
    print_error "Project and repo names are required"
    return 1
  fi
  echo "https://github.com/$project_name/$repo_name.git"
}

generate_dx_github_repo_url(){
  local repo_name=$1

  # load the configuration
  load_config
  
  if [[ -z "$repo_name" ]]; then
    print_error "Repo name is required"
    return 1
  fi
  if [[ -z "${DX_GITHUB_URL:-}" ]]; then
    print_error "DX_GITHUB_URL is not configured"
    return 1
  fi
  echo "$DX_GITHUB_URL/$repo_name.git"
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
        -p|--project)
          project_arg=$2
          shift
          ;;
        -r|--repo)
          repo_arg=$2
          shift
          ;;                  
        -u|--url)
          url_arg=$2
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

        clone)
          shift
          if [[ -n "$url_arg" ]]; then
            print_info "$url_arg"
            # parse if is a github url or dev.azure.com url
            # if is github, call cmd_github_clone
            # if is dev.azure.com, call cmd_azure_clone

            if [[ $url_arg == *"github.com"* ]]; then
              cmd_github_clone "$url_arg"
            elif [[ $url_arg == *"dev.azure.com"* ]]; then
              cmd_azure_clone "$url_arg"
            else
              print_error "Error: Unsupported url: $url_arg"
              exit 1
            fi
            exit 0
          fi

          if [[ -n "$project_arg" ]] && [[ -n "$repo_arg" ]]; then
            generate_ado_repo_url "$project_arg" "$repo_arg"
            generate_github_repo_url "$project_arg" "$repo_arg"
            exit 0
          fi

          if [[ -n "$name_arg" ]]; then
            url=$(generate_dx_github_repo_url "$name_arg")
            print_info "Url: $url"
            cmd_github_clone "$url"
            exit 0
          fi
          ;;

        *)
            print_error "Error: [$command] Unsupported command"
            usage
            exit 1
            ;;
    esac

}

main "$@"
