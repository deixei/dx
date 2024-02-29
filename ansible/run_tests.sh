#!/bin/bash

# TODO: need to move into the ansible script

start_dir=$(pwd)
current_dir=$(dirname "$0")

verbosity="-v"

echo -e "# Test Execution\n" > $current_dir/test_results.md

if [[ -f ~/.dx/user_az_config.sh ]]; then
    . ~/.dx/user_az_config.sh
else
    echo "No user_az_config.sh file found"
fi

if [[ -f ~/.dx/user_git_config.sh ]]; then
    . ~/.dx/user_git_config.sh
else
    echo "No user_git_config.sh file found"
fi

# Iterate over all directories in the current directory
for dir in $current_dir/*/
do
    # Extract the directory name
    dir_name=$(basename "${dir}")

    echo "Directory: ${dir}"
    mkdir -p "${dir}/test_results"
    
    cat "${dir}/README.md" >> $current_dir/test_results.md

    filepattern="test_*.ansible.yml"

    files=$(find "${dir}" -type f -name 'test_*.ansible.yml')
    for file in $files
    do
        # If the file exists, print its name
        if [ -f "${file}" ]; then

            echo -e "### Suite ${dir_name} - Use case: ${file}\n" >> $current_dir/test_results.md

            echo "##[group] Suite ${dir_name} - Use case: ${file}"
            
            filename=$(basename "${file}")

            echo "" > "${dir}/test_results/${filename}.txt"
            ANSIBLE_CONFIG=${dir}/ansible.cfg ansible-playbook "${file}" $verbosity > "${dir}/test_results/${filename}.txt"

            # Extract summary information from the output file
            summary=$(grep -A 5 "PLAY RECAP" "${dir}/test_results/${filename}.txt")

            # Print the summary to the console
            cat "${dir}/test_results/${filename}.txt" 

            # Append the summary to the test results
            echo -e "\`\`\`txt\n${summary}\n\`\`\`\n" >> $current_dir/test_results.md
            
            echo "##[endgroup]"
        fi
        echo -e "\n" >> $current_dir/test_results.md
    done

done

cd $start_dir
