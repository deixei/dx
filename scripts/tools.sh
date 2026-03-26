#!/bin/bash
set -e  # Exit on error
if [ -n "${ZSH_VERSION-}" ]; then
  setopt PIPE_FAIL
elif [ -n "${BASH_VERSION-}" ]; then
  set -o pipefail
fi
IFS=$'\n\t'

subcommand="tools"
script_dir=$(dirname "$0")
source "$script_dir/common.sh"
source "$script_dir/tools_registry.sh"
if [ -n "${ZSH_VERSION-}" ]; then
  trap 'print_error "Error on line $LINENO."' ZERR
else
  trap 'print_error "Error on line $LINENO."' ERR
fi
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
  echo "  show              Show all managed tools with status and version"
  echo "  install all       Install missing tools and update installed ones"
  echo "  install <name>    Install a specific tool"
  echo "  update all        Update all installed tools"
  echo "  update <name>     Update a specific tool"
  echo
  print_info "Managed tools:"
  echo "  $MANAGED_TOOLS" | tr '\n' ', '
  echo
  echo
  print_info "Examples:"
  echo "  dx tools show"
  echo "  dx tools install all"
  echo "  dx tools install dotnet"
  echo "  dx tools update gh"
}

_validate_tool_name() {
  local target="$1"
  for name in $MANAGED_TOOLS; do
    if [[ "$name" == "$target" ]]; then
      return 0
    fi
  done
  print_error "Unknown tool: $target"
  print_info "Available tools:"
  for name in $MANAGED_TOOLS; do
    echo "  $name"
  done
  return 1
}

command_show() {
  print_warning "### Managed Tools Status ###"
  echo
  printf "%-15s %-12s %s\n" "TOOL" "STATUS" "VERSION"
  printf "%-15s %-12s %s\n" "----" "------" "-------"
  for name in $MANAGED_TOOLS; do
    local status version
    if tool_check "$name"; then
      status="installed"
      version=$(tool_version "$name")
    else
      status="missing"
      version="-"
    fi
    printf "%-15s %-12s %s\n" "$name" "$status" "$version"
  done
}

command_install() {
  local target="$1"
  if [[ "$target" == "all" ]]; then
    local installed_count=0
    local updated_count=0
    local installed_now_count=0
    local failed_count=0
    local failed_tools=""

    for name in $MANAGED_TOOLS; do
      if ! tool_check "$name"; then
        print_info "Installing $name..."
        if tool_install "$name" 2>&1; then
          print_success "$name installed"
          installed_now_count=$((installed_now_count + 1))
        else
          print_error "$name installation failed (continuing...)"
          failed_tools="$failed_tools $name"
          failed_count=$((failed_count + 1))
        fi
      else
        installed_count=$((installed_count + 1))
        print_info "$name is already installed, updating..."
        if tool_update "$name" 2>&1; then
          print_success "$name updated"
          updated_count=$((updated_count + 1))
        else
          print_error "$name update failed (continuing...)"
          failed_tools="$failed_tools $name"
          failed_count=$((failed_count + 1))
        fi
      fi
    done

    echo
    print_info "Summary: installed $installed_now_count, updated $updated_count, already present $installed_count, failed $failed_count"
    if [[ $failed_count -gt 0 ]]; then
      print_warning "Failed tools:$failed_tools"
      print_info "Run 'dx tools install <name>' to retry individually"
    fi
  else
    _validate_tool_name "$target" || return 1
    if ! tool_check "$target"; then
      print_info "Installing $target..."
      tool_install "$target"
      print_success "$target installed"
    else
      print_info "$target is already installed, updating..."
      tool_update "$target"
      print_success "$target updated"
    fi
  fi
}

command_update() {
  local target="$1"
  if [[ "$target" == "all" ]]; then
    for name in $MANAGED_TOOLS; do
      if tool_check "$name"; then
        print_info "Updating $name..."
        tool_update "$name"
        print_success "$name updated"
      else
        print_warning "$name is not installed, skipping"
      fi
    done
  else
    _validate_tool_name "$target" || return 1
    if tool_check "$target"; then
      print_info "Updating $target..."
      tool_update "$target"
      print_success "$target updated"
    else
      print_warning "$target is not installed. Use: dx tools install $target"
    fi
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
          if [[ -z "$command" ]]; then
            command=$1
          elif [[ -z "$name_arg" ]]; then
            name_arg=$1
          fi
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
          command_show
          ;;
        install)
          if [[ -z "$name_arg" ]]; then
            print_error "Error: specify a tool name or 'all'"
            usage
            exit 1
          fi
          command_install "$name_arg"
          ;;
        update)
          if [[ -z "$name_arg" ]]; then
            print_error "Error: specify a tool name or 'all'"
            usage
            exit 1
          fi
          command_update "$name_arg"
          ;;
        *)
          print_error "Error: [$command] Unsupported command"
          usage
          exit 1
          ;;
    esac
}

main "$@"
