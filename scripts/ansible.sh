#!/bin/bash
subcommand="ansible"
script_dir=$(dirname "$0")
source $script_dir/common.sh

ansible_collections_target_folder="$home_dir/.ansible/collections"

usage() {
  print_warning "### DX tools - $subcommand ###"
  echo
  print_info "Usage: dx $subcommand [options] [command]"
  echo
  print_info "Options:"
  echo "  -h, --help      Show this help message and exit"
  echo
  print_info "Commands:"
  echo "  find           Find ansible galaxy collections"
  echo "  build          Build and install ansible galaxy collections. Example: dx ansible build --name 'common'"
  echo "  show           Show things"
  echo "  play           Run ansible playbook"
  echo "  modules        !Run ansible python module"
  echo "  new            !Create new ansible galaxy collection"
  echo "  test           Run ansible playbooks test cases. Example: dx ansible test --name 'common'"

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
  local name=$2  

  find $home_dir -name "galaxy.yml" -exec dirname {} \; | while read -r dir; do
    if [[ -n "$name" ]]; then
      if [[ $dir == *"$name"* ]]; then
        print_info "Found: $dir"
        if [[ $action == "build" ]]; then
          build_and_install $dir
        fi
      fi
    else
      print_info "Found: $dir"
      if [[ $action == "build" ]]; then
        build_and_install $dir
      fi
    fi


  done
}

cmd_run(){
    local playbook_name="$1"
    local inventory_path="$2"
    local verbosity="$3"

    if [[ -z "$inventory_path" ]]; then
        inventory_path="inventories/development"
    fi

    if [[ -z "$playbook_name" ]]; then
        playbook_name="play.ansible.yml"
    fi

    if [[ -z "$verbosity" ]]; then
        verbosity=""
    else
        verbosity="-$verbosity"
    fi

    print_warning "Running ansible"
    # load the configuration
    load_config

    ansible-playbook -i $inventory_path $playbook_name $verbosity
}

cmd_run_modules(){
    local module_name="$1"
    local module_args="$2"
    local verbosity="$3"

    if [[ -z "$module_name" ]]; then
        module_name="nothing"
    fi

    if [[ -z "$module_args" ]]; then
        module_args="${module_name}"
    fi

    if [[ -z "$verbosity" ]]; then
        verbosity=""
    else
        verbosity="-$verbosity"
    fi

    print_warning "Running ansible python module"
    # load the configuration
    load_config

    args_file="modules/args/$module_args.json"
    if [[ ! -f $args_file ]]; then
      cp $script_dir/../templates/ansible_module_args.json $args_file
    fi

    if [[ -f $args_file ]]; then
        cp $args_file $args_file.tmp

        sed -i "s/{{AZURE_CLIENT_ID}}/$AZURE_CLIENT_ID/g" $args_file
        sed -i "s/{{AZURE_SECRET}}/$AZURE_SECRET/g" $args_file
        sed -i "s/{{AZURE_TENANT}}/$AZURE_TENANT/g" $args_file

        python3 -m pdb modules/$module_name.py $args_file
        #rm $args_file.tmp
    else
        print_error "##[command] Error: File not found: $args_file"
    fi

}

command_test_playbooks() {
  print_info "Executing ansible playbooks test cases"
  # load the configuration
  load_config
  local name="$1"
  local start_dir=$(pwd)
  echo "Start dir: $start_dir"

  verbosity="-v"

  mkdir -p "${start_dir}/test_results"
  echo -e "# Test Execution\n" > $start_dir/test_results/test_results.md

  pass_counter=0
  error_counter=0
  total_counter=0

  while read -r dir; do
  
      if [[ -n "$name" ]]; then
      if [[ $dir == *"$name"* ]]; then
        print_info "Found: $dir"
        files=$(find "${dir}" -type f -name 'test_*.ansible.yml')
        for file in $files
        do
            collection_name=$(basename "${dir}")
            file_name=$(basename "${file}")
            file_parent=$(basename $(dirname "${file}"))
            test_case_dir=$(dirname "${file}")
            echo -e "## Suite '${collection_name}'.'${file_parent}' - Use case: '${file_name}'\n" >> $start_dir/test_results/test_results.md

            echo "" > "${start_dir}/test_results/${file_name}.txt"
            ANSIBLE_CONFIG=${test_case_dir}/ansible.cfg ansible-playbook "${file}" $verbosity > "${start_dir}/test_results/${file_name}.txt"
            total_counter=$((total_counter + 1))
            # Extract summary information from the output file
            summary=$(grep -A 5 "PLAY RECAP" "${start_dir}/test_results/${file_name}.txt")

            # Use awk to extract the value of failed
            failed_count=$(echo $summary | awk -F'failed=' '{print $2}' | awk '{print $1}')

            # Check if failed count is different from 0
            if [ $failed_count -ne 0 ]; then
              echo "There were failures: '${collection_name}'.'${file_parent}'.'${file_name}'"
              error_counter=$((error_counter + 1))
            else
              echo "No failures: '${collection_name}'.'${file_parent}'.'${file_name}'"
              pass_counter=$((pass_counter + 1))
            fi

          # Append the summary to the test results
            echo -e "\`\`\`txt\n${summary}\n\`\`\`\n" >> $start_dir/test_results/test_results.md

            #cat "${start_dir}/test_results/${file_name}.txt" 
            
            
        done


      fi
    fi


  done < <(find $home_dir -name "galaxy.yml" -exec dirname {} \;)
  echo -e "## Summary\n\nTotal: ${total_counter}\nPass: ${pass_counter}\nFail: ${error_counter} " >> $start_dir/test_results/test_results.md

  if [ $error_counter -ne 0 ]; then
   exit 1
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
        -i|--inventory)
          inventory_arg=$2
          shift
          ;;
        -v|--verbosity)
          verbosity_arg=$2
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
        find)
          shift
          search_galaxy_collection "show" "$name_arg"
          ;;
        build)
          shift
          search_galaxy_collection "build" "$name_arg"
          ;;
        test)
          shift
          command_test_playbooks "$name_arg"
          ;;
        show)
          shift
          command_show
          ;;
        play)
          shift
          if [[ -z "$name_arg" ]]; then
              print_error "Error: Missing name argument (--name or -n)"
              exit 1
          fi          
          cmd_run "$name_arg" "$inventory_arg" "$verbosity_arg"
          ;;
        modules)
          shift
          if [[ -z "$name_arg" ]]; then
              print_error "Error: Missing name argument (--name or -n)"
              exit 1
          fi          
          cmd_run_modules "$name_arg" "$inventory_arg" "$verbosity_arg"
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