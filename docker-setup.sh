#!/bin/bash
# If following error is sent: /bin/bash^M - use sed -i -e 's/\r$//' docker-setup.sh 

# Variables
gitdir=$(pwd)

GREEN='\033[0;32m' # Green color for use in echo
YELLOW='\033[1;33m' # Green color for use in echo
BLUE='\033[1;34m' # Green color for use in echo
RED='\033[0;31m' # Red color for use in echo
NC='\033[0m' # No Color for use in echo

web_dir=/srv/www

echo "setting up directory ($web_dir)"
echo ""
# Creates directory
### Check if a directory does not exist ###
if [ ! -d $web_dir ] 
then
    echo "Directory $web_dir does not exists."
    echo "System username? (used to setup directory '$web_dir')"
    read myusername

    echo "Creating directory. (The following actions use sudo. To prevent the use of sudo, please setup '$web_dir' before running this program again)"
    
    sudo mkdir -p $web_dir

    # 2. set your user as the owner
    sudo chown -R $myusername $web_dir
    # 3. set the web server as the group owner
    sudo chgrp -R www-data $web_dir
    # 4. 755 permissions for everything
    sudo chmod -R 755 $web_dir
    # 5. New files and folders inherit 
    # group ownership from the parent folder
    chmod g+s $web_dir

    echo "Directory permission is set."
else
    echo "Directory already created."
    # Old section that ask if permission is set. This may be activated later.
    # echo "Is persmission set? [Y]" 
    # read input
    # if [[ $input == "n" || $input == "N" ]]; then
    #     echo "Directory permission is not set."
    #     echo "Setting directory permissions. (The following actions use sudo. To prevent the use of sudo, please setup '$web_dir' before running this program again)"

    #     # 2. set your user as the owner
    #     sudo chown -R $myusername $web_dir
    #     # 3. set the web server as the group owner
    #     sudo chgrp -R www-data $web_dir
    #     # 4. 755 permissions for everything
    #     sudo chmod -R 755 $web_dir
    #     # 5. New files and folders inherit 
    #     # group ownership from the parent folder
    #     chmod g+s $web_dir

    #     echo "Directory permission is set."
    # fi
fi

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



echo ""
echo -e "${BLUE}Setting up web servers${NC}"
echo "How many webservers do you wish to setup?"
while true; do
    read webserverCount;
    if [[ ! $webserverCount =~ ^[0-9]+$ ]] ; then
        echo "The provided webserver count was not an integer. Please try again"
    else
        break
    fi
done

echo ""
for (( i=1; i<=$webserverCount; i++ )) do #Create .env file for domain
    echo "What is the $i. websevers domain (ex. example.com, test.com) (not www.test.com) ?"
    read domain # a check if domain exist is needed
    echo ""
    while true; do
        echo "What type of webserver do you need? (lamp, nginx, wp)"
        read serverType
        if [[ $serverType == "lamp" || $serverType == "nginx" || $serverType == "wp" ]] ; then
            echo ""
            break
        else
            echo "The provided webserver type is not supported"
            echo "Supported server types: lamp, nginx, wp"
        fi
    done

    dockerSucess=false
    case $serverType in
        lamp)
            echo -e "${BLUE}Setting up lamp webserver $NC"
            echo ""
            envFile="$domain.env"
            envFileLocation=$gitdir/docker/env/lamp/$envFile
            if [ ! -f "$gitdir/docker/env/lamp/$domain.env" ]; then
                echo ".env file for this domain does not exist";
                echo "There was no configuration file found for this domain."
                echo "Would you like to create a new configuration file for this domain? [y]"
                read createConfig
                echo ""
                if [[ $createConfig == "y" || $createConfig == "Y" ]]; then
                    echo "Setting VIRTUAL_HOST..."
                    echo "VIRTUAL_HOST=$domain" >> $gitdir/docker/env/lamp/$envFile
                    echo "Setting VIRTUAL_PORT..."
                    echo "VIRTUAL_PORT=80" >> $gitdir/docker/env/lamp/$envFile
                    echo "Setting ServerName..."
                    echo "ServerName=$domain" >> $gitdir/docker/env/lamp/$envFile
                    echo "Setting LETSENCRYPT_HOST..."
                    echo "LETSENCRYPT_HOST=$domain" >> $gitdir/docker/env/lamp/$envFile
                    echo ""
                    echo "Please provide mail to use for SSL certificat:"
                    read sslEmail
                    echo "Setting LETSENCRYPT_EMAIL..."
                    echo "LETSENCRYPT_EMAIL=$sslEmail" >> $gitdir/docker/env/lamp/$envFile

                    echo ""
                    echo "Have you created custom configuration for this apache on this server? [y]"
                    read customConfig
                    echo ""
                    if [[ $customConfig == "y" || $customConfig == "Y" ]]; then
                        echo "Please provide location for 'apache2.conf', 'default-host.conf', 'evasive.conf', 'security2.conf'"
                        echo "This must be an url to a folder containing 'apache2.conf', 'default-host.conf', 'evasive.conf', 'security2.conf':"
                        read serverConfigLocation
                        echo "configLink=$serverConfigLocation" >> $gitdir/docker/env/lamp/$envFile
                    else
                        echo "Using default apache and php configuration..."
                        echo "configLink='https://raw.githubusercontent.com/The0mikkel/auto-multicontainer-setup/master/configuration/lamp'" >> $gitdir/docker/env/lamp/$envFile
                    fi

                else 
                    echo "Using default config file. This may break the webserver you are trying to start."
                    echo "The default domain is: web1.localhost"
                    envFile="default-lamp.env"
                    envFileLocation=$gitdir/docker/env/lamp/$envFile
                fi
                echo ""
            fi
            echo "Setting up folder for $domain"
            if [ ! -d $web_dir/$domain ]; then mkdir $web_dir/$domain; fi
            echo "Copying docker files and configuration file..."
            cp $gitdir/docker/lamp/lamp.docker-compose.yml $web_dir/$domain/docker-compose.yml
            cp $gitdir/docker/lamp/lamp.dockerfile $web_dir/$domain/dockerfile
            cp $envFileLocation $web_dir/$domain/.env
            if [ ! -d $web_dir/$domain/app/ ]; then 
                echo "Creating directories for app..."
                mkdir $web_dir/$domain/app/; 
            else 
                echo "Directory for app, is already created."
            fi
            if [ ! -d $web_dir/$domain/mysql/ ]; then 
                echo "Creating directories for mysql..."
                mkdir $web_dir/$domain/mysql/; 
            else 
                echo "Directory for mysql, is already created."
            fi
            if [ ! -f $web_dir/$domain/app/index.html ]; then
                echo "Adding standard success page to app folder..."
                echo "Dette er en test side for $domain" > $web_dir/$domain/app/index.html
            else
                echo "An index page is already located in the app folder."
            fi
            echo ""
            echo -e "${BLUE}Building image and deploying webserver/container${NC}"
            cd $web_dir/$domain
            docker-compose --log-level CRITICAL up -d --build && dockerSucess=true
            cd /$gitdir
            echo ""
            echo "cleaning up after docker setup"
            echo "Removing configuration file..."
            rm $web_dir/$domain/.env
            echo "Removing docker files..."
            rm $web_dir/$domain/dockerfile
            rm $web_dir/$domain/docker-compose.yml
        ;;
        nginx)
            echo "This is still being worked on..."
        ;;
        wp) #Needs a way to reset folder, when new container is being set up
            # This setup is mainly comming from this blog post: https://www.datanovia.com/en/lessons/docker-wordpress-production-deployment/
            echo -e "${BLUE}Setting up Wordpress webserver $NC"
            echo ""
            if [ -d $web_dir/$domain ]; then 
                echo "A webserver is already located on this domain ($domain). To setup a wordpress installation, the old webserver needs to be removed."
                echo "Would you like to remove the old installation? [y]"
                read removeOld
                if [[ $removeOld == "y" || $removeOld == "Y" ]] ; then
                    echo "Removing old wordpress installation... (This action is using sudo. To prevent use of sudo, quit action and delete direcoroty '$web_dir/$domain' before running this program again)"
                    echo ""
                    sudo rm -R $web_dir/$domain
                    echo "Remove complete"
                    echo ""
                    mkdir -p $web_dir/$domain/
                else
                    echo ""
                    echo -e "${RED}Webserver setup at $domain have been skiped, due to an error!${NC}"
                    echo "---------------------------------------------------------"
                    echo ""
                    continue
                fi
                
            else 
                mkdir -p $web_dir/$domain/
            fi

            cd $web_dir/$domain/

            # Copying needed files
            compose_file="docker-compose.yml"
            auto_compose_file="wp-auto-config.yml"
            cp $gitdir/docker/wp/wp.docker-compose.yml docker-compose.yml
            cp $gitdir/docker/wp/wp.auto-config.yml wp-auto-config.yml

            mkdir -p mysql
            mkdir -p wordpress

            cp -r $gitdir/configuration/wp/wpcli .
            cp -r $gitdir/configuration/wp/config .

            env_file=".env"
            cp $gitdir/docker/env/wp/default-wp.env $web_dir/$domain/$env_file

            echo "What is the project name? (Must be lower-case, no spaces and no invalid path chars)"
            read project_name
            echo ""
            echo "What should the username be for your user? (wordpress and database)"
            read user_name
            echo ""
            echo "What should the password be for your user? (no special chars)"
            read pass_word
            echo ""
            echo "What should the email be for your user?"
            read email
            echo ""
            echo "What should the website title be for your site?"
            read website_title
            echo ""
            echo "URL for site:"
            website_url="https://$domain"
            echo $website_url
            echo ""
            echo "What should the subdomain url be for phpmyadmin? (ex. sql)"
            read phpmyadmin_url_prefix
            phpmyadmin_url="$phpmyadmin_url_prefix.$domain"
            echo "phpmyadmin url: $phpmyadmin_url"
            echo ""

            echo ---SETTING PRODUCTION ENVIRONMENT VARIABLES----
            # echo $env_file and $compose_file backups \(before update\) are available in _trash folder

            # Update automatically .env file
            # --------------------------------------------------------------------------
            sed -i -e "/COMPOSE_PROJECT_NAME/s/wordpress/$project_name/" $env_file

            # Update User password and name
            sed -i -e "/DATABASE_PASSWORD/s/password/$pass_word/" $env_file
            sed -i -e "/DATABASE_USER/s/root/$user_name/" $env_file
            sed -i -e "/WORDPRESS_ADMIN_PASSWORD/s/wordpress/$pass_word/" $env_file
            sed -i -e "/WORDPRESS_ADMIN_USER/s/wordpress/$user_name/" $env_file
            sed -i -e "/WORDPRESS_ADMIN_EMAIL/s/your-email@example.com/$email/" $env_file

            # Update website info
            url=$website_url
            url_without_http=$domain              # Replace https
            url_without_www=${url_without_http/www./}
            url=$(echo $url | sed 's;/;\\/;g') # Escape / in url
            sed -i -e "s/WORDPRESS_WEBSITE_URL=\"http:\/\/localhost\"/WORDPRESS_WEBSITE_URL='http:\/\/$domain'/" $env_file
            sed -i -e "s/WORDPRESS_WEBSITE_URL_WITHOUT_HTTP=localhost/WORDPRESS_WEBSITE_URL_WITHOUT_HTTP=$domain/" $env_file
            sed -i -e "/WORDPRESS_WEBSITE_TITLE/s/My Blog/$website_title/" $env_file
            # sed -i -e "/WORDPRESS_WEBSITE_URL/s/http:\/\/localhost/$url/" $env_file
            sed -i -e "/WORDPRESS_WEBSITE_URL_WITHOUT_WWW/s/example.com/$url_without_www/" $env_file
            sed -i -e "/PHPMYADMIN_WEBSITE_URL_WITHOUT_HTTP/s/sql.example.com/$phpmyadmin_url/" $env_file
            sed -i -e "/WAIT_SLEEP_INTERVAL/s/60/10/" $env_file

            # Update automatically docker-compose.yml file
            # --------------------------------------------------------------------------
            sed -i -e "s/https:\/\/www.change-me-with-your-domain.com/$url/" $compose_file

            echo ""
            echo "$phpmyadmin_url"
            echo ""
            echo -e "${GREEN}Project settings have been updated! $NC"
            echo ""
            echo -e "${YELLOW}If you want to check settings before setting up server, you can do it now. Press enter to create containers.$NC"
            echo "Configuration file can be located at: $web_dir/$domain/$env_file"
            read test
            echo -e "${BLUE}Building image and deploying webserver/container${NC}"
            echo -e "${YELLOW}This may take som time...$NC"
            echo ""

            # docker-compose build && docker-compose up -d && docker-compose run --rm healthcheck && dockerSucess=true
            docker-compose up -d --build && docker-compose -f docker-compose.yml -f wp-auto-config.yml run --rm wp-auto-config && dockerSucess=true
            cd /$gitdir
            if [[ $dockerSucess == true ]]; then
                echo ""
                echo -e "${YELLOW}The wordpress installation, is installed and conifgured.$NC"
            fi
        ;;
    esac
    if [[ $dockerSucess == true ]]; then
        echo ""
        echo -e "${GREEN}Webserver at $domain have been deployed!${NC}"
        echo "---------------------------------------------------------"
        echo ""
    else 
        echo ""
        echo -e "${RED}An error occurred, please read through why this happen, and rerun this script when the bug has been solved...${NC}"
        echo -e "${RED}Exiting${NC}"
        exit
    fi
done
echo "All webservers have been deployed!"
echo "Enjoy!"
echo "";
