#!/bin/bash
set -o allexport
source .env
set +o allexport

while getopts d: flag; do
    case "${flag}" in
    d) web_dir=${OPTARG} ;;
    *) ;;
    esac
done

echo ""
echo -e "${BLUE}Setting up web servers${NC}"
echo "How many webservers do you wish to setup?"
while true; do
    read -r webserverCount
    if [[ ! $webserverCount =~ ^[0-9]+$ ]]; then
        echo "The provided webserver count was not an integer. Please try again"
    else
        break
    fi
done

echo ""
for ((i = 1; i <= webserverCount; i++)); do #Create .env file for domain
    while true; do
        echo "What type of webserver do you need? (lamp, nginx, wp, portainer, openvpn, php-stack, laravel)"
        read -r serverType
        if [[ $serverType == "lamp" || $serverType == "nginx" || $serverType == "wp" || $serverType == "php-stack" || $serverType == "laravel" ]]; then
            echo ""
            echo "What is the $i. websever domain (ex. example.com, test.com) ?"
            read -r domain # a check if domain exist is needed
            echo ""
            break
        elif [[ $serverType == 'portainer' || $serverType == "openvpn" ]]; then
            echo ""
            break
        else
            echo "The provided webserver type is not supported"
            echo "Supported server types: lamp, nginx, wp and portainer"
        fi
    done

    dockerSucess=false
    case $serverType in
    lamp)
        echo -e "${BLUE}Setting up lamp webserver $NC"
        echo ""
        envFile="${domain}.env"
        envFileLocation="${gitdir}/docker/env/lamp/$envFile"
        if [ ! -f "${gitdir}/docker/env/lamp/${domain}.env" ]; then
            echo ".env file for this domain does not exist"
            echo "There was no configuration file found for this domain."
            echo "Would you like to create a new configuration file for this domain? [y]"
            read -r createConfig
            echo ""
            if [[ $createConfig == "y" || $createConfig == "Y" ]]; then
                echo "Setting VIRTUAL_HOST..."
                echo "VIRTUAL_HOST=${domain}" >>"${gitdir}/docker/env/lamp/$envFile"
                echo "Setting VIRTUAL_PORT..."
                echo "VIRTUAL_PORT=80" >>"${gitdir}/docker/env/lamp/$envFile"
                echo "Setting ServerName..."
                echo "ServerName=${domain}" >>"${gitdir}/docker/env/lamp/$envFile"
                echo "Setting LETSENCRYPT_HOST..."
                echo "LETSENCRYPT_HOST=${domain}" >>"${gitdir}/docker/env/lamp/$envFile"
                echo ""
                echo "Please provide mail to use for SSL certificat:"
                read -r sslEmail
                echo "Setting LETSENCRYPT_EMAIL..."
                echo "LETSENCRYPT_EMAIL=$sslEmail" >>"${gitdir}/docker/env/lamp/$envFile"

                echo ""
                echo "Have you created custom configuration for this apache on this server? [y]"
                read -r customConfig
                echo ""
                if [[ $customConfig == "y" || $customConfig == "Y" ]]; then
                    echo "Please provide location for 'apache2.conf', 'default-host.conf', 'evasive.conf', 'security2.conf'"
                    echo "This must be an url to a folder containing 'apache2.conf', 'default-host.conf', 'evasive.conf', 'security2.conf':"
                    read -r serverConfigLocation
                    echo "configLink=$serverConfigLocation" >>"${gitdir}/docker/env/lamp/$envFile"
                else
                    echo "Using default apache and php configuration..."
                    echo "configLink='https://raw.githubusercontent.com/The0mikkel/auto-multicontainer-setup/master/configuration/lamp'" >>"${gitdir}/docker/env/lamp/$envFile"
                fi

            else
                echo "Using default config file. This may break the webserver you are trying to start."
                echo "The default domain is: web1.localhost"
                envFile="default-lamp.env"
                envFileLocation="${gitdir}/docker/env/lamp/$envFile"
            fi
            echo ""
        fi
        echo "Setting up folder for ${domain}"
        if [ ! -d "${web_dir}/${domain}" ]; then mkdir "${web_dir}/${domain}"; fi
        echo "Copying docker files and configuration file..."
        cp "${gitdir}/docker/lamp/lamp.docker-compose.yml" "${web_dir}/${domain}/docker-compose.yml"
        cp "${gitdir}/docker/lamp/lamp.dockerfile" "${web_dir}/${domain}/dockerfile"
        cp "$envFileLocation" "${web_dir}/${domain}/.env"
        if [ ! -d "${web_dir}/${domain}/app/" ]; then
            echo "Creating directories for app..."
            mkdir "${web_dir}/${domain}/app/"
        else
            echo "Directory for app, is already created."
        fi
        if [ ! -d "${web_dir}/${domain}/mysql/" ]; then
            echo "Creating directories for mysql..."
            mkdir "${web_dir}/${domain}/mysql/"
        else
            echo "Directory for mysql, is already created."
        fi
        if [ ! -f "${web_dir}/${domain}/app/index.html" ]; then
            echo "Adding standard success page to app folder..."
            echo "Dette er en test side for ${domain}" >"${web_dir}/${domain}/app/index.html"
        else
            echo "An index page is already located in the app folder."
        fi
        echo ""
        echo -e "${BLUE}Building image and deploying webserver/container${NC}"
        cd "${web_dir}/${domain}" || exit
        docker compose up -d --build && dockerSucess=true
        cd "/${gitdir}" || exit
        ;;
    nginx)
        echo "I'm very sorry"
        echo "This is still being worked on..."
        ;;
    wp) #Needs a way to reset folder, when new container is being set up
        # This setup is mainly comming from this blog post: https://www.datanovia.com/en/lessons/docker-wordpress-production-deployment/
        echo -e "${BLUE}Setting up Wordpress webserver $NC"
        echo ""
        if [ -d ${web_dir}/${domain} ]; then
            echo "A webserver is already located on this domain (${domain}). To setup a wordpress installation, the old webserver needs to be removed."
            echo "Would you like to remove the old installation? [y]"
            read removeOld
            if [[ $removeOld == "y" || $removeOld == "Y" ]]; then
                echo "Removing old wordpress installation... (This action is using sudo. To prevent use of sudo, quit action and delete direcoroty '${web_dir}/${domain}' before running this program again)"
                echo ""
                sudo rm -R ${web_dir}/${domain}
                echo "Remove complete"
                echo ""
                mkdir -p ${web_dir}/${domain}/
            else
                echo ""
                echo -e "${RED}Webserver setup at ${domain} have been skiped, due to an error!${NC}"
                echo "---------------------------------------------------------"
                echo ""
                continue
            fi

        else
            mkdir -p ${web_dir}/${domain}/
        fi

        cd ${web_dir}/${domain}/

        # Copying needed files
        compose_file="docker-compose.yml"
        auto_compose_file="wp-auto-config.yml"
        cp ${gitdir}/docker/wp/wp.docker-compose.yml docker-compose.yml
        cp ${gitdir}/docker/wp/wp.auto-config.yml wp-auto-config.yml

        mkdir -p mysql
        mkdir -p wordpress

        cp -r ${gitdir}/configuration/wp/wpcli .
        cp -r ${gitdir}/configuration/wp/config .

        env_file=".env"
        cp ${gitdir}/docker/env/wp/default-wp.env ${web_dir}/${domain}/$env_file

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
        website_url="https://${domain}"
        echo $website_url
        echo ""
        echo "What should the subdomain url be for phpmyadmin? (ex. sql)"
        read phpmyadmin_url_prefix
        phpmyadmin_url="$phpmyadmin_url_prefix.${domain}"
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
        url_without_http=${domain} # Replace https
        url_without_www=${url_without_http/www./}
        url=$(echo $url | sed 's;/;\\/;g') # Escape / in url
        sed -i -e "s/WORDPRESS_WEBSITE_URL=\"http:\/\/localhost\"/WORDPRESS_WEBSITE_URL='http:\/\/${domain}'/" $env_file
        sed -i -e "s/WORDPRESS_WEBSITE_URL_WITHOUT_HTTP=localhost/WORDPRESS_WEBSITE_URL_WITHOUT_HTTP=${domain}/" $env_file
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
        echo "Configuration file can be located at: ${web_dir}/${domain}/$env_file"
        read test
        echo -e "${BLUE}Building image and deploying webserver/container${NC}"
        echo -e "${YELLOW}This may take som time...$NC"
        echo ""

        # docker compose build && docker compose up -d && docker compose run --rm healthcheck && dockerSucess=true
        docker compose up -d --build && docker compose -f docker-compose.yml -f wp-auto-config.yml run --rm wp-auto-config && dockerSucess=true
        cd /${gitdir}
        if [[ $dockerSucess == true ]]; then
            echo ""
            echo -e "${YELLOW}The wordpress installation, is installed and conifgured.$NC"
        fi
        # Needed cleanup of directory?
        ;;
    portainer)
        if [[ ! "$(docker ps -q -f name=portainer)" ]]; then
            echo -e "${BLUE}Setting up Portainer$NC"
            echo ""
            if [ -d "${web_dir}/portainer/" ]; then
                echo "Portainer exist in some form or another - Aborting install"
                dockerSucess=false
            else
                mkdir "${web_dir}/portainer/"
                cp "${gitdir}/docker/portainer/docker-compose.yml" "${web_dir}/portainer/docker-compose.yml"
                cd "${web_dir}/portainer/" || exit
                docker compose up -d && dockerSucess=portainer
                cd "/${gitdir}" || exit
            fi
        else
            echo -e "${RED}Portainer is already running!"
            echo "Please remove the current running Portainer container, before trying to setup a new instance"
            dockerSucess=customError
        fi
        ;;
    openvpn)
        if [[ ! "$(docker ps -q -f name=openvpn-as)" ]]; then
            echo -e "${BLUE}Setting up Openvpn$NC"
            echo ""
            if [ ! -d ${web_dir}/openvpn ]; then
                mkdir ${web_dir}/openvpn
            fi
            if [ ! -d ${web_dir}/openvpn/config ]; then
                mkdir ${web_dir}/openvpn/config
            fi
            cd ${web_dir}/openvpn/
            cp /${gitdir}/docker/openVpn/docker-compose.yml docker-compose.yml
            docker compose up -d --build
            # sudo docker create --name=openvpn-as \
            # --restart=always \
            # -v ${web_dir}/openvpn/config:/config \
            # -e INTERFACE=eth0 \
            # -e PGID=1001 -e PUID=1001 \
            # -e TZ=Europe/London \
            # --net=host --privileged \
            # linuxserver/openvpn-as
            dockerSucess=openvpn
            cd /${gitdir}
        else
            echo -e "${RED}OpenVpn is already running!"
            echo "Please remove the current running openVpn container, before trying to setup a new instance"
            dockerSucess=customError
        fi
        ;;
    php-stack)
        echo -e "${BLUE}Setting up php-stack webserver $NC"
        echo ""
        envFile="${domain}.env"
        envFileLocation="${gitdir}/docker/env/php-stack/$envFile"
        if [ ! -f "${gitdir}/docker/env/php-stack/${domain}.env" ]; then
            echo ".env file for this domain does not exist"
            echo "There was no configuration file found for this domain."
            echo "Would you like to create a new configuration file for this domain? [y]"
            read -r createConfig
            echo ""
            if [[ $createConfig == "y" || $createConfig == "Y" ]]; then
                createdEnvFile="${gitdir}/docker/env/php-stack/$envFile"
                # Domain related env variables
                echo "Setting server name... (${domain})"
                echo "SERVERNAME=${domain}" >>"${createdEnvFile}"
                echo "Setting VIRTUAL_HOST... (${domain})"
                echo "VIRTUAL_HOST=${domain}" >>"${createdEnvFile}"
                echo "Setting LETSENCRYPT_HOST... (${domain})"
                echo "LETSENCRYPT_HOST=${domain}" >>"${createdEnvFile}"

                # Customizable variables
                echo ""
                read -r -p "Please provide a domain prefix for phpmyadmin to use [leave empty for default]: " phpmyadminPrefix
                phpmyadminPrefix=${phpmyadminPrefix:-phpmyadmin}
                echo "Setting MYSQL_DATABASE... (${phpmyadminPrefix})"
                echo "VIRTUAL_HOST_DB_PREFIX=${phpmyadminPrefix}" >>"${createdEnvFile}"
                echo ""
                read -r -p "Please provide mail to use for SSL certificat: " sslEmail
                sslEmail=${sslEmail:-"example@example.com"}
                echo "Setting LETSENCRYPT_EMAIL... (${sslEmail})"
                echo "LETSENCRYPT_EMAIL=${sslEmail}" >>"${createdEnvFile}"
                echo ""
                read -r -p "Please provide a database name to use [leave empty for default]: " databaseName
                databaseName=${databaseName:-"php"}
                echo "Setting MYSQL_DATABASE... (${databaseName})"
                echo "MYSQL_DATABASE=${databaseName}" >>"${createdEnvFile}"
                echo ""
                read -r -p "Please provide a database username to use [leave empty for default]: " databaseUsername
                databaseUsername=${databaseUsername:-"php"}
                echo "Setting MYSQL_USER... (${databaseUsername})"
                echo "MYSQL_USER=${databaseUsername}" >>"${createdEnvFile}"
                echo ""
                read -r -s -p "Please provide a database user passowrd for ${databaseUsername} to use [leave empty for random]: " databasePassword
                randomString=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
                databasePassword=${databasePassword:-${randomString}}
                echo ""
                echo "Setting MYSQL_PASSWORD..."
                echo "MYSQL_PASSWORD=${databasePassword}" >>"${createdEnvFile}"
                echo ""
                read -r -s -p "Please provide a database root passowrd for to use [leave empty for random (recommended)]: " databaseRootPassword
                randomString=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
                databaseRootPassword=${databaseRootPassword:-${randomString}}
                echo ""
                echo "Setting MYSQL_ROOT_PASSWORD..."
                echo "MYSQL_ROOT_PASSWORD=${databaseRootPassword}" >>"${createdEnvFile}"
                echo ""
                read -r -p "Please provide a timezone for the webserver [leave empty for system timezone (recommended)]: " timezone
                systemTimezone=$(cat /etc/timezone)
                timezone=${timezone:-${systemTimezone}}
                echo "Setting TIMEZONE... (${timezone})"
                echo "TIMEZONE=${timezone}" >>"${createdEnvFile}"
            else
                echo "Using default config file. This may break the webserver you are trying to start."
                echo "The default domain is: php-stack.localhost"

                envFile="default-php-stack.env"
                envFileLocation="${gitdir}/docker/env/php-stack/$envFile"
            fi
            echo ""
        fi
        echo "Setting up folder for ${domain}"
        if [ ! -d "${web_dir}/${domain}" ]; then mkdir "${web_dir}/${domain}"; fi

        echo "Copying docker files and configuration file..."
        # Copying configuration files
        cp "${gitdir}/docker/php-stack/docker-compose.yml" "${web_dir}/${domain}/docker-compose.yml"
        cp "${gitdir}/docker/php-stack/dockerfile" "${web_dir}/${domain}/dockerfile"
        cp "$envFileLocation" "${web_dir}/${domain}/.env"

        # Generating folders and their files
        if [ ! -d "${web_dir}/${domain}/conf/" ]; then
            echo "Creating directories for conf..."
            mkdir "${web_dir}/${domain}/conf/"
            cp "${gitdir}/configuration/php-stack/apache2.conf" "${web_dir}/${domain}/conf/apache2.conf"
        else
            echo "Directory for conf, is already created."
        fi

        if [ ! -d "${web_dir}/${domain}/app/" ]; then
            echo "Creating directories for app..."
            mkdir "${web_dir}/${domain}/app/"
        else
            echo "Directory for app, is already created."
        fi

        if [ ! -d "${web_dir}/${domain}/mariadb/" ]; then
            echo "Creating directories for mariadb..."
            mkdir "${web_dir}/${domain}/mariadb/"
        else
            echo "Directory for mariadb, is already created."
        fi

        if [ ! -d "${web_dir}/${domain}/mariadb-backup/" ]; then
            echo "Creating directories for mariadb-backup..."
            mkdir "${web_dir}/${domain}/mariadb-backup/"
        else
            echo "Directory for mariadb-backup, is already created."
        fi

        if [ ! -f "${web_dir}/${domain}/app/index.html" ]; then
            echo "Adding standard success page to app folder..."
            echo "Dette er en test side for ${domain}" >"${web_dir}/${domain}/app/index.html"
        else
            echo "An index page is already located in the app folder."
        fi

        # Run docker-compose
        echo ""
        echo -e "${BLUE}Building image and deploying webserver / containers${NC}"
        cd "${web_dir}/${domain}" || exit
        docker compose up -d --build && dockerSucess=true
        cd "/${gitdir}" || exit
        ;;
    laravel)
        echo "Setting up folder for ${domain}"
        cd "${web_dir}" || exit

        echo "Running Laravel docker container, to setup default Laravel installation"
        docker run --rm \
            -v "$(pwd)":/opt \
            -w /opt \
            laravelsail/php81-composer:latest \
            bash -c "laravel new ${domain} && cd ${domain} && php ./artisan sail:install --with=mysql,redis,meilisearch,mailhog,selenium "

        cd "${web_dir}/${domain}" || exit

        if sudo -n true 2>/dev/null; then
            sudo chown -R $USER: .
        else
            echo -e "${WHITE}Please provide your password so we can make some final adjustments to your application's permissions.${NC}"
            echo ""
            sudo chown -R $USER: .
            echo ""
            echo -e "${WHITE}Thank you!${NC}"
        fi

        rm "docker-compose.yml"
        cp "${gitdir}/docker/laravel/docker-compose.yml" "${web_dir}/${domain}/docker-compose.yml"

        echo ""

        createdEnvFile=".env"
        echo "We need to setup some things first - Let's get started!"
        echo ""
        read -r -p "Please provide a database name to use [leave empty for default]: " databaseName
        databaseName=${databaseName:-"php"}
        echo "Setting DB_DATABASE... (${databaseName})"
        sed -i -e "/DB_DATABASE/s/=${domain}/=${databaseName}/" "${createdEnvFile}"
        echo ""
        read -r -p "Please provide a database username to use [leave empty for default]: " databaseUsername
        databaseUsername=${databaseUsername:-"php"}
        echo "Setting DB_USERNAME... (${databaseUsername})"
        sed -i -e "/DB_USERNAME/s/=sail/=${databaseUsername}/" "${createdEnvFile}"
        echo ""
        read -r -s -p "Please provide a database user passowrd for ${databaseUsername} to use [leave empty for random]: " databasePassword
        randomString=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        databasePassword=${databasePassword:-${randomString}}
        echo ""
        echo "Setting DB_PASSWORD..."
        sed -i -e "/DB_PASSWORD/s/=password/=${databasePassword}/" "${createdEnvFile}"
        echo ""

        echo " " >>"${createdEnvFile}"
        echo "Setting server name... (${domain})"
        echo "SERVERNAME=${domain}" >>"${createdEnvFile}"
        echo "Setting VIRTUAL_HOST... (${domain})"
        echo "VIRTUAL_HOST=${domain}" >>"${createdEnvFile}"
        echo "Setting LETSENCRYPT_HOST... (${domain})"
        echo "LETSENCRYPT_HOST=${domain}" >>"${createdEnvFile}"
        echo ""
        read -r -p "Please provide a domain prefix for phpmyadmin to use [leave empty for default]: " phpmyadminPrefix
        phpmyadminPrefix=${phpmyadminPrefix:-phpmyadmin}
        echo "Setting MYSQL_DATABASE... (${phpmyadminPrefix})"
        echo "VIRTUAL_HOST_DB_PREFIX=${phpmyadminPrefix}" >>"${createdEnvFile}"
        echo ""
        read -r -p "Please provide mail to use for SSL certificat: " sslEmail
        sslEmail=${sslEmail:-"example@example.com"}
        echo "Setting LETSENCRYPT_EMAIL... (${sslEmail})"
        echo "LETSENCRYPT_EMAIL=${sslEmail}" >>"${createdEnvFile}"
        read -r -p "Please provide a timezone for the webserver [leave empty for system timezone (recommended)]: " timezone
        systemTimezone=$(cat /etc/timezone)
        timezone=${timezone:-${systemTimezone}}
        echo "Setting TIMEZONE... (${timezone})"
        echo "TIMEZONE=${timezone}" >>"${createdEnvFile}"

        echo ""
        echo "Custom setup done!"
        echo ""

        docker compose up -d --build && dockerSucess=true
        cd "/${gitdir}" || exit
        ;;
    esac
    if [[ $dockerSucess == true ]]; then
        echo ""
        echo -e "${GREEN}Webserver at ${domain} have been deployed!${NC}"
        echo "---------------------------------------------------------"
        echo ""
    elif [[ $dockerSucess == 'portainer' ]]; then
        echo ""
        echo -e "${GREEN}Portainer have been deployed, and can be accessed through localip:9000${NC}"
        echo "---------------------------------------------------------"
        echo ""
    elif [[ $dockerSucess == 'openvpn' ]]; then
        echo ""
        echo -e "${GREEN}OpenVpn have been deployed, and can be accessed through localip:943${NC}"
        echo "---------------------------------------------------------"
        echo ""
    elif [[ $dockerSucess == 'customError' ]]; then
        echo ""
        echo -e "${YELLOW}The webserver you were trying to setup threw an error message.${NC}"
        echo -e "${YELLOW}Continuing${NC}"
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
echo ""
