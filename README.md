# auto-multicontainer-setup
Auto multicontainer script, that can easily setup multiple webservers on one server, with the help of a nginx reverse proxy.
The script is currently supporting lamp and wp installations.

## Sources
This script is based of severel other repositories, that have been automated in a singel bash script.
Sources:<br>
nginx reverse proxy:<br>
[Kassambara (Github repository)](https://github.com/kassambara/nginx-multiple-https-websites-on-one-server)<br>
[Kassambara (Guide)](https://www.datanovia.com/en/lessons/how-host-multiple-https-websites-on-one-server/)<br>
lamp stack:<br>
[Mattrayner (Dockerhub)](https://hub.docker.com/r/mattrayner/lamp)<br>

## How to run it
to run script do the following:<br>
`git clone https://github.com/The0mikkel/auto-multicontainer-setup`<br>
`cd auto-multicontainer-setup`<br>
`./docker-setup.sh`<br>

If you see following error `/bin/bash^M`<br>
Run following command `sed -i -e 's/\r$//' docker-setup.sh && ./docker-setup.sh`<br>

## Disclaimer
I am in no way a professionel in any of the fields this software works with, and there may be bugs and security issues in the provided software.<br>
I will to some extend try to keep this code maintained, but this software is provided as is, and should be looked through before use.<br>
I do not take any responsebility for any damage this software may do.
