#!/bin/bash
set -o allexport
source .env
set +o allexport

while getopts d: flag
do
    case "${flag}" in
        d) web_dir=${OPTARG};;
        *)
    esac
done

# Script to setup web dir
echo "setting up directory ($web_dir)"
echo ""
# Creates directory
### Check if a directory does not exist ###
if [ ! -d ${web_dir} ] 
then
    echo "Directory ${web_dir} does not exists."
    echo "System username? (used to setup directory '${web_dir}')"
    read myusername

    echo "Creating directory. (The following actions use sudo. To prevent the use of sudo, please setup '${web_dir}' before running this program again)"
    
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root, to setup the folder. Do you want to continue? [y]" 
        read decision
        if [ $decision != "y" ]; then
            echo -e "${YELLOW}Stopping program!${NC}";
            exit 1;
        fi
    fi

    sudo mkdir -p ${web_dir}

    # 2. set your user as the owner
    sudo chown -R $myusername ${web_dir}
    # 3. set the web server as the group owner
    sudo chgrp -R www-data ${web_dir}
    # 4. 755 permissions for everything
    sudo chmod -R 755 ${web_dir}
    # 5. New files and folders inherit 
    # group ownership from the parent folder
    chmod g+s ${web_dir}

    echo "Directory permission is set."
else
    echo "Directory already created - Expecting permission to correctly be set."
fi