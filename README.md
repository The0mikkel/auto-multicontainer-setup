# auto-multicontainer-setup
Auto multicontainer script, that can easily setup multiple webservers on one server, with the help of a nginx reverse proxy.
The script is currently supporting lamp and wp installations.

## Sources
This script is based of severel other repositories, that have been automated in a singel bash script.<br>
Sources:<br>
Nginx reverse proxy:<br>
[Kassambara (Github repository)](https://github.com/kassambara/nginx-multiple-https-websites-on-one-server)<br>
[Kassambara (Guide)](https://www.datanovia.com/en/lessons/how-host-multiple-https-websites-on-one-server/)<br>
Lamp stack:<br>
[Mattrayner (Dockerhub)](https://hub.docker.com/r/mattrayner/lamp)<br>

## How to run it
### Cloning code
To download the code, use the following code:<br>
`git clone https://github.com/The0mikkel/auto-multicontainer-setup\
cd auto-multicontainer-setup`<br>

### Running the automated script
`./docker-setup.sh`<br>

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

#### LAMP


#### WP

## Disclaimer
I am in no way a professionel in any of the fields this software works with, and there may be bugs and security issues in the provided software.<br>
I will to some extend try to keep this code maintained, but this software is provided as is, and should be looked through before use.<br>
I do not take any responsebility for any damage this software may do.
