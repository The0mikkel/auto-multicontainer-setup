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

# Check docker is running and can be accessed
if docker > /dev/null 2>&1 ; then
    :
else
    echo -e "${YELLOW}Docker is not running.${NC}";
    exit 1;
fi

# Script to setup nginx reverse proxy in the web_dir directory
if [[ ! "$(docker ps -q -f name=nginx-proxy)" && ! "$(docker ps -q -f name=nginx-proxy-gen)" && ! "$(docker ps -q -f name=nginx-proxy-letsencrypt)" ]]; then
    echo ""
    echo -e "${BLUE}setting up nginx reverse proxy $NC"

    if [ -d "${web_dir}"/nginx-reverse-proxy ]; then 
        echo "A previus nginx proxy installation is already located in ${web_dir} and not running. To setup a new nginx reverse proxy, the old installetion needs to be removed."
        echo "Do you want to proceed? [y]"
        read decision
        if [ "$decision" != "y" ]; then

            echo -e "${YELLOW}Stopping program!${NC}";
            exit 1;

        fi
        echo "Removing nginx reverse proxy data and folder... (This action is using sudo. To prevent use of sudo, quit action and delete direcoroty '${web_dir}/nginx-reverse-proxy' before running this program again)"
        sudo rm -R "${web_dir}"/nginx-reverse-proxy
    fi
    echo ""

    echo "Creating folders..."
    mkdir "${web_dir}"/nginx-reverse-proxy
    mkdir "${web_dir}"/nginx-reverse-proxy/certs
    mkdir "${web_dir}"/nginx-reverse-proxy/conf.d
    mkdir "${web_dir}"/nginx-reverse-proxy/html
    mkdir "${web_dir}"/nginx-reverse-proxy/vhost.d
    mkdir "${web_dir}"/nginx-reverse-proxy/fallback
    mkdir "${web_dir}"/nginx-reverse-proxy/acme
    
    echo "Dowloading and creating files..."
    # Docker compose file
    cp "${gitdir}"/docker/nginx-proxy/docker-compose.yml "${web_dir}"/nginx-reverse-proxy/docker-compose.yml

    # Adding custom nginx conf for hardening
    cp "$gitdir"/configuration/nginx-proxy/hardening.conf "${web_dir}"/nginx-reverse-proxy/conf.d/hardening.conf

    # Update nginx.tmpl: Nginx configuration file template
    curl -s https://raw.githubusercontent.com/jwilder/nginx-proxy/master/nginx.tmpl> "${web_dir}"/nginx-reverse-proxy/nginx.tmpl

    # Inserting fallback page
    echo "Something seems off. Did you land the right place?" > "${web_dir}"/nginx-reverse-proxy/fallback/index.html

    echo ""
    echo -e "${BLUE}starting nginx reverse proxy${NC}"
    echo ""
    if [[ ! "$(docker network ls | grep nginx-proxy)" ]]; then
        echo "Creating nginx-proxy network ..."
        docker network create nginx-proxy
    else
        echo "nginx-proxy network exists."
    fi

    # Creates the reverse proxy with the 
    # nginx, nginx-gen and nginx-letsencrypt containers
    cd ${web_dir}/nginx-reverse-proxy/ || ( echo "Error entering nginx-reverse-proxy/nginx-proxy folder" && exit )
    docker-compose up -d
    cd /$gitdir || ( echo "Error entering $gitdir folder" && exit )

    echo ""
    echo -e "${GREEN}Nginx proxy have been deployed!${NC}"
else 
    echo ""
    echo -e "${YELLOW}Nginx proxy is already deployed!${NC}"
fi