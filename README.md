# Auto multicontainer setup
Auto multicontainer script, that can easily setup multiple webservers on one server, with the help of a nginx reverse proxy.
The script is currently supporting lamp and wp installations.

***This software has only been tested on debian***

## Sources
This script is based of severel other repositories, that have been automated in a singel bash script.<br>
Sources:<br>
Nginx reverse proxy:<br>
[Kassambara (Github repository)](https://github.com/kassambara/nginx-multiple-https-websites-on-one-server)<br>
[Kassambara (Guide)](https://www.datanovia.com/en/lessons/docker-wordpress-production-deployment/)<br>
Lamp stack:<br>
[Mattrayner (Dockerhub)](https://hub.docker.com/r/mattrayner/lamp)<br>

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
Run following command `sed -i -e 's/\r$//' docker-setup.sh && ./docker-setup.sh`<br>

### The automated script
The script adds the new webservers in the `/srv/www` directory.<br>
This means, that if any server that is already located (with domain name) in this folder, may cause the code to fail.

If the directory `/srv/www` does not exist, the script will create this, as well as setting the right permission (this usses sudo).<br>
If the directory does exist, the software will assume that the right permission have been set.

If a previus folder called "nginx-reverse-proxy" exist and the services "nginx", "nginx-gen" and "nginx-letsencrypt" is running, the scripts continues as if the proxy is installed and running.

After this, you can instert an integer, to say how many webservers you would like to setup.<br>
And the software will then go through the setup of every webserver.

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
```
VIRTUAL_HOST
VIRTUAL_PORT
LETSENCRYPT_HOST
LETSENCRYPT_EMAIL
ServerName
configLink
```

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

##### LETSENCRYPT_HOST

The `LETSENCRYPT_HOST`, is the email-address used to make the SSL certificate. Therefore this email should be changed.


This is used to set up the nginx proxy.

##### ServerName

The `ServerName`, is the name of the server.

This is used to set the container name.

##### configLink

The `configLink`, is the url-address of a folder on a webserver containing `apache2.conf`, `default-host.conf`, `evasive.conf` and `security2`.

This is used to fetch apache setup files when building the docker image.

### WP

## Disclaimer
I am in no way a professionel in any of the fields this software works with, and there may be bugs and security issues in the provided software.<br>
I will to some extend try to keep this code maintained, but this software is provided as is, and should be looked through before use.<br>
I do not take any responsebility for any damage this software may do.
