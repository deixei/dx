#!/bin/bash
subcommand="git"
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

}

command_show() {
  print_info "Showing things"
  # load the configuration
  load_config

  # TODO: Add more
}


command_git_clone() {

  local repo_url=$1
  local project_name=$2
  local repo_name=$3

  base_folder="$home_dir/repos/$project_name"

  if [ ! -d "$base_folder" ]; then
      mkdir -p $base_folder
  fi

  folder="$base_folder/$repo_name"
  print_warning "Runing: [git clone $repo_url] into folder: [$folder]."

  if [ ! -d "$folder" ]; then
    git clone "$repo_url" "$folder"
  else
    print_info "The $folder folder already exists."
  fi
}

cmd_github_clone() {
  local repo_url=$1
  # parse the repo url similar to https://github.com/deixei/factory.git into project_name and repo_name
  # project_name=deixei
  # repo_name=factory
  project_name=$(echo $repo_url | awk -F'/' '{print $4}')
  repo_name=$(echo $repo_url | awk -F'/' '{print $5}' | awk -F'.' '{print $1}')

  print_info "Project name: $project_name"
  print_info "Repo name: $repo_name"
  print_info "Url: $repo_url"

  command_git_clone $repo_url $project_name $repo_name
}

cmd_azure_clone(){
  local repo_url=$1

  project_name=$(echo $repo_url | awk -F'/' '{print $6}')
  repo_name=$(echo $repo_url | awk -F'/' '{print $8}')

  print_info "Project name: $project_name"
  print_info "Repo name: $repo_name"
  print_info "Url: $repo_url"

  command_git_clone $repo_url $project_name $repo_name
}

generate_ado_repo_url(){
  local project_name=$1
  local repo_name=$2

  # load the configuration
  load_config

  echo "$DX_ADO_URL/$project_name/$repo_name/_git/$repo_name"
}

generate_github_repo_url(){
  local project_name=$1
  local repo_name=$2

  echo "https://github.com/$project_name/$repo_name.git"
}

generate_dx_github_repo_url(){
  local repo_name=$1

  # load the configuration
  load_config
  
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

        clone)
          shift
          if [[ -n "$url_arg" ]]; then
            echo "$url_arg"
            # parse if is a github url or dev.azure.com url
            # if is github, call cmd_github_clone
            # if is dev.azure.com, call cmd_azure_clone

            if [[ $url_arg == *"github.com"* ]]; then
              cmd_github_clone $url_arg
            elif [[ $url_arg == *"dev.azure.com"* ]]; then
              cmd_azure_clone $url_arg
            else
              print_error "Error: Unsupported url: $url_arg"
              exit 1
            fi
            exit 0
          fi

          if [[ -n "$project_arg" ]] && [[ -n "$repo_arg" ]]; then
              generate_ado_repo_url $project_arg $repo_arg
              generate_github_repo_url $project_arg $repo_arg
              exit 0
          fi

          if [[ -n "$name_arg" ]]; then
            url=$(generate_dx_github_repo_url $name_arg)
            echo "Url: $url"
            cmd_github_clone $url
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