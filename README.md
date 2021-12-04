# Auto multicontainer setup
Auto multicontainer script, that can easily setup multiple webservers on one server in a docker inverionment, with the help of a nginx reverse proxy.
The script is currently supporting lamp, wp and Portainer installations.

***This software has only been tested on Debian, Kali and Ubuntu***

## Table of contents
- [Sources](#Sources)
- [How to run it](#How-to-run-it)
    - [Prerequisites](#Prerequisites)
    - [Cloning code](#Cloning-code)
    - [Running the automated script](#Running-the-automated-script)
- [Reverse proxy](#Reverse-proxy)
    - [Modes](#Modes)
    - [NGINX reverse proxy](#NGINX-reverse-proxy)
- [The webservers](#The-webservers)
    - [LAMP](#LAMP)
    - [PHP-stack](#PHP-stack)
    - [WP (Wordpress)](#WP)
    - [Portainer](#Portainer)
- [Disclaimer](#Disclaimer)

## Sources
This script is based of severel other repositories, that have been automated in a singel bash script.<br>
Sources:<br>
Nginx reverse proxy:<br>
[Kassambara (Github repository)](https://github.com/kassambara/nginx-multiple-https-websites-on-one-server)<br>
[Kassambara (Guide)](https://www.datanovia.com/en/lessons/docker-wordpress-production-deployment/)<br>
Lamp stack:<br>
[Mattrayner (Dockerhub)](https://hub.docker.com/r/mattrayner/lamp)<br>

Most of these, has been modified in different ways, to make them more stable and work better with this setup.

## How to run it
### Prerequisites
#### Needed software
To run this script, you need to have the following softwares installed
- Git
- Docker
- curl

These can be downloaded with the following command:<br>
*ubuntu/debian:*
```bash
sudo apt-get install git docker curl -y
```
### Cloning code
To download the code, use the following code:<br>
```bash
git clone https://github.com/The0mikkel/auto-multicontainer-setup;
cd auto-multicontainer-setup;
```

### Running the automated script
Use the following code to run the script:
```bash
./docker-setup.sh;
```

If you see following error `/bin/bash^M`<br>
Run following command `chmod u+x docker-setup.sh && sed -i -e 's/\r$//' docker-setup.sh && ./docker-setup.sh`<br>

#### *Flags*
Flags can be used to customize the process of the program.

*-d [dir]* | The `d` flag is used to set the directory: `-d /srv/www`<br>
*-r [reverse proxy]* | The `r` flag is used to set the reverse proxy: `-r nginx-proxy`

### The automated script
The script adds the new webservers in the `/srv/www` directory.<br>
This means, that if any server that is already located (with domain name) in this folder, may cause the code to fail.

If the directory `/srv/www` does not exist, the script will create this, as well as setting the right permission (this usses sudo).<br>
If the directory does exist, the software will assume that the right permission have been set.

If a previus folder called "nginx-reverse-proxy" exist and the services "nginx", "nginx-gen" and "nginx-letsencrypt" is running, the scripts continues as if the proxy is installed and running.

After this, you can instert an integer, to say how many webservers you would like to setup.<br>
And the software will then go through the setup of every webserver.

## Reverse proxy

### Modes
It is possible to enable and disable auto setup of Reverse proxy.<br>
The software is currently setup and configured to always add a NGINX reverse proxy, that automaticly detects new containers, and adds them to the reverse proxy.

Currently, all webservers and containers in this software is setup to use this reverse proxy. In the future, other reverse proxies may be added to this software.

The automatic NGINX reverse proxy setup, can be disabled by includeding the flag `-r none`.<br>
To run the setup, then call: 
```bash
./docker-setup.sh -r none;
```

### NGINX reverse proxy
The included reverse proxy, in this software, is a NGINX reverse proxy, that works with a [docker-gen](https://hub.docker.com/r/nginxproxy/docker-gen) to automaticly detect new containers, and register them in the reverse proxy. The main piece of this reverse proxy, is the NGINX proxy, that works with a [template](https://github.com/nginx-proxy/nginx-proxy/blob/main/nginx.tmpl), that from the [docker-gen](https://hub.docker.com/r/nginxproxy/docker-gen) container, is able to build configurations for any new containers coming online, without any downtime.

SSL certificates is handled by the [acme-companion](https://hub.docker.com/r/nginxproxy/acme-companion), which automaticly creates a SSL certificate for routes, that needs them. These certificates are made with "Let's Encrypt", and is automaticly kept up to date. To read more about this, view the GitHub repository for the container: https://github.com/nginx-proxy/acme-companion

All of this, is made by [nginx-proxy](https://github.com/nginx-proxy)

An extension, that this software does, to this stack, is a fallback route, for any requests, that does not have any route. This route is set to be http://fallback.reverse-proxy.localhost, and is made by a httpd container. The content of this webserver, can be found in `./nginx-reverse-proxy directory/fallback.`

The NGINX reverse proxy can be modified after install, in the `./nginx-reverse-proxy directory`

If any existing nginx-reverse-proxy is present, but none of the containers are running, the software will try to reinstall (delete and install) the folder, and any previus setup may be lost.<br>
Before the software executes this, it asks, if you want to proceed.

If any of the three nginx-proxy containers are running, the software will assume that the proxy is good to go. 

#### [Container list](https://hub.docker.com/u/nginxproxy)
- nginx-proxy: [NGINX](https://hub.docker.com/_/nginx)
- nginx-proxy-gen: [Docker-gen](https://hub.docker.com/r/nginxproxy/docker-gen)
- nginx-proxy-letsencrypt: [acme-companion](https://hub.docker.com/r/nginxproxy/acme-companion)
- nginx-proxy-fallback: [httpd](https://hub.docker.com/_/httpd)

*All inspiration to this setup, has come from [this guide](https://www.datanovia.com/en/lessons/docker-wordpress-production-deployment/).*

## The webservers

### LAMP
The LAMP server is based on the [`mattrayner/lamp:latest-1804`](https://hub.docker.com/r/mattrayner/lamp)<br>
but is further costomized in the script.<br>
This customization comes, as the possibility to automaticly insert `apache2.conf`, `default-host.conf`, `evasive.conf` and `security2` into the container.<br>
These files are the main Apache configuration file, apache configuration for the virtual hosts, the apache mod "evasive" and the mod "ModSecurity".

Theses mods ("evasive" and "ModSecurity"), is to protect agains ddos and acts like a firewalls.

To customize `apache2.conf`, `default-host.conf`, `evasive.conf` and `security2`<br>
a link to a folder on a webserver with these files, can be provided to the configuration.
All four files needs to present on the linked webserver.

The default configuration for this script can be located in `configuration/lamp/`

A .env file can be created in the `docker/env/lamp/` folder, with the domain name<br>
to automate the process.
The .env file in `docker/env/lamp/` needs to contain the following:<br>
- VIRTUAL_HOST
- VIRTUAL_PORT
- LETSENCRYPT_HOST
- LETSENCRYPT_EMAIL
- ServerName
- configLink

The default values can be seen in the `default-lamp.env`

You can choose to not have a .env in advance, where the script then will ask you question and automaticly make a .env file for the domain.
When manually setting these up in the script, you are only asked for email, which i used for `LETSENCRYPT_EMAIL`, and asked if you have a configLink.<br>
If you don't have a configLink, the script will use the default configLink<br>
(https://raw.githubusercontent.com/The0mikkel/auto-multicontainer-setup/master/configuration/lamp).<br>
The rest of the settings is derived from the domain name of the server.

After the script has run, the new .env file we be located in `docker/env/lamp/`, with the name of the domain.

When starting this server, you are also building the image for it.

After the webserver has been deployed, please view the log of the container, to insure, that the container is infact running.<br>
In this log, you will also get the username and password for the standard mysql user.<br>
**Please write the password down and/or change it shortly after deployment**

A phpmyadmin page will be available at `$domain/phpmyadmin`

#### Inserting files

When the server is deployed, the files for the server will be located at `/srv/www/$domain`<br>
In this folder there will be two folders. `app` and `mysql`.

##### `app` folder
The app folder is where all the serverfiles goes.<br>
In here you will find a `index.html` file, which is just a short demo site.

##### `mysql` folder
The `mysql` folder, is where all the mysql files goes.<br>
This means, that the container can be deleted and reinstalled in the same directory, and keep all of the database files.

#### .env variables
##### VIRTUAL_HOST
The `VIRTUAL_HOST`, is the url for the webserver (ex. example.com).

This is used to set up the nginx proxy.

##### VIRTUAL_PORT
The `VIRTUAL_PORT`, is the port to use for the webserver. This is standard 80, and should always be 80.


This is used to set up the nginx proxy.

##### LETSENCRYPT_HOST

The `LETSENCRYPT_HOST`, is the url for the webserver (ex. example.com).

This is used to set up the nginx proxy.

##### LETSENCRYPT_EMAIL

The `LETSENCRYPT_EMAIL`, is the email-address used to make the SSL certificate. Therefore this email should be changed.


This is used to set up the nginx proxy.

##### ServerName

The `ServerName`, is the name of the server.

This is used to set the container name.

##### configLink

The `configLink`, is the url-address of a folder on a webserver containing `apache2.conf`, `default-host.conf`, `evasive.conf` and `security2`.

This is used to fetch apache setup files when building the docker image.

### PHP-stack

PHP stack is a multicontainer php server, with a custom build [php:apache](https://hub.docker.com/_/php) container, which enables mysqli, apache rewrite and uses defualt php.ini production configuration. Besides the main web container, there is 3 additional containers.<br>
- [mariadb](https://hub.docker.com/_/mariadb) for database. 
- [mariadb-cron-backup](https://hub.docker.com/r/fradelg/mysql-cron-backup) is a mysql backup container, that is setup to take a backup of the database every day, at 23:00, and keeps it for 30 days. It compresses it with a GZIP level of 9.
- [phpmyadmin](https://hub.docker.com/_/phpmyadmin) for easy access to database, when needed. *(It is recomended to keep this stopped, unless activly used)*

#### Folder structure

When the server is deployed, the files for the server will be located at `/srv/www/$domain`<br>
In this folder there will be two folders. `app`, `mariadb`, `mariadb-backup`, `dump` and `conf`.

##### `app` folder
The app folder is where all the serverfiles goes.<br>
In here you will find a `index.html` file, which is just a short demo site.

##### `mariadb` folder
The `mariadb` folder, is where all the database files goes.<br>
This means, that the container can be deleted and reinstalled in the same directory, and keep all of the database files.

##### `mariadb-backup` folder
The `mariadb-backup` folder, is where all the database backup files goes.

##### `dump` folder
The `dump` folder, is the docker-entrypoint-initdb.d.

##### `conf` folder
The `conf` folder, is where any configuration of the apache server, is located.<br>
Here you will find a apache2.conf file, with some preset hardened settings.

#### .env variables

To be able to run this stack, a number of things, need to be known.<br>
These are all saved in the .env file, that are saved in the

Variables:
- SERVERNAME
- VIRTUAL_HOST
- VIRTUAL_HOST_DB_PREFIX
- LETSENCRYPT_HOST
- LETSENCRYPT_EMAIL
- MYSQL_DATABASE
- MYSQL_USER
- MYSQL_PASSWORD
- MYSQL_ROOT_PASSWORD
- TIMEZONE


##### SERVERNAME
Servername for the stack. Also used in the names of the containers.<br>
It is automaticly set to the domain of the new server.

##### VIRTUAL_HOST
Domain for the new server. This is used for the NGINX reverse proxy.

##### VIRTUAL_HOST_DB_PREFIX
Domain prefix, for the phpmyadmin page. Used in `$VIRTUAL_HOST_DB_PREFIX.$VIRTUAL_HOST`

##### LETSENCRYPT_HOST
Domain for the SSL certificat. Should be the same as the domain

##### LETSENCRYPT_EMAIL
Email connected to the SSL certificat.

##### MYSQL_DATABASE
Database to be created with the stack.

##### MYSQL_USER
User to create with the stack.

##### MYSQL_PASSWORD
Password for the MYSQL_USER.

##### MYSQL_ROOT_PASSWORD
Root password of the mariadb. Should be very strong.

##### TIMEZONE
Timezone of the PHP server and the database, to make sure times a synchronized.

### WP
The Wordpress server is based on the `[wordpress:latest](https://hub.docker.com/_/wordpress)`, but is setup after the [Docker WordPress Production Deployment](https://www.datanovia.com/en/lessons/docker-wordpress-production-deployment/) guide by Alboukadel Kassambara.

The script downloads the [wordpress-docker-compose](https://github.com/kassambara/wordpress-docker-compose) GitHub repository, and replaces the standard `docker-compose.yml` with a modified `docker-compose.yml` that have "redirectnonwww" container removed, as well as replacing the `ports` with `exposed` in the phpmyadmin container, for it to work better with multiple wordpress servers running.


The script will ask multiple questions, to setup the wordpress installation.

These are the following:
- Projekt name
- User name
- User password
- Email
- Website title
- Subdomain / Prefix for phpmyadmin page

After the user has given the right information, the server will setup a .env file in the given directory for the wordpress installation (`/srv/www/$domain`).<br>
This .env file can then be inspected by the user, before the software continues, to ensure that all information is given correctly.<br>
This is for the most part not necessary.

When the webserver is launched, then the user should go to the webservers domain to finish the Wordpress setup.<br>
This include, but limited to, username and password for Wordpress.

The install of the server is currently only automatic, so that the website is setup and configured when going live.

The phpmyadmin will be available on the `$prefix.$domain` url.

At this point the wordpress install should be ready to use, just log ind with the cridentials provided doing install.

### Portainer
It is possible to install [Portainer](https://www.portainer.io/), with this software.

Portainer is a lightweight management UI for Docker, that is easely installed.

This code runs the standard install of Portainer, just for easy of use, when already setting up multiple webservers with this program.

A custom docker-compose file is made, with the most basic install of Portainer. This docker-compose file can be inspected in `/docker/portainer/docker-compose.yml`

This is all runned in the directory `/srv/www/portainer`, and makes it possible to easely update the container.<br>
This container is not integrated with the NGINX reverse proxy

## Disclaimer
I am in no way a professionel in any of the fields this software works with, and there may be bugs and security issues in the provided software.<br>
I will to some extend try to keep this code maintained, but this software is provided as is, and should be looked through before use.<br>
I do not take any responsebility for any damage this software may do.
