#!/bin/bash
# Script to setup nginx reverse proxy in the web_dir directory
if [[ ! "$(docker ps -q -f name=nginx)" && ! "$(docker ps -q -f name=nginx-gen)" && ! "$(docker ps -q -f name=nginx-letsencrypt)" ]]; then
    echo ""
    echo -e "${BLUE}setting up nginx reverse proxy $NC"

    if [ -d $web_dir/nginx-reverse-proxy ]; then 
        echo "A previus nginx proxy installation is already located in $web_dir. To setup a new nginx reverse proxy, the old installetion needs to be removed."
        echo "Press enter to continue"
        read test
        echo "Removing nginx reverse proxy... (This action is using sudo. To prevent use of sudo, quit action and delete direcoroty '$web_dir/nginx-reverse-proxy' before running this program again)"
        sudo rm -R $web_dir/nginx-reverse-proxy
    fi
    echo ""
    mkdir $web_dir/nginx-reverse-proxy
    echo "Donloading files..."
    # Download a nginx-proxy template
    git clone https://github.com/kassambara/nginx-multiple-https-websites-on-one-server $web_dir/nginx-reverse-proxy

    # Update nginx.tmpl: Nginx configuration file template
    rm -rf $web_dir/nginx/nginx-proxy/nginx.tmpl
    curl -s https://raw.githubusercontent.com/jwilder/nginx-proxy/master/nginx.tmpl> $web_dir/nginx-reverse-proxy/nginx-proxy/nginx.tmpl

    # Remove unnecessary files and folders
    cd $web_dir/nginx-reverse-proxy
    rm -rf your-website-one.com your-website-two.com README.Rmd README.md .gitignore .Rbuildignore .git

    # Adding custom nginx conf
    cp $gitdir/configuration/nginx-proxy/hardening.conf $web_dir/nginx-reverse-proxy/nginx-proxy/conf.d/hardening.conf

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
    cd $web_dir/nginx-reverse-proxy/nginx-proxy/
    docker-compose up -d
    cd /$gitdir

    echo ""
    echo -e "${GREEN}Nginx proxy have been deployed!${NC}"
    echo "---------------------------------------------------------"
else 
    echo ""
    echo -e "${YELLOW}Nginx proxy is already deployed!${NC}"
    echo "---------------------------------------------------------"
fi