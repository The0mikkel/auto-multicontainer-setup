# auto-multicontainer-setup
Auto multicontainer script, that can easily setup multiple webservers on one server, with the help of a nginx reverse proxy.
The script is currently supporting lamp and wp installations.

This script is based of severel other repositories, that have been automated in a singel bash script.
Sources:<br>
nginx reverse proxy:<br>
[Kassambara (Github repository)](https://github.com/kassambara/nginx-multiple-https-websites-on-one-server)<br>
[Kassambara (Guide)](https://www.datanovia.com/en/lessons/how-host-multiple-https-websites-on-one-server/)<br>
lamp stack:<br>
[Mattrayner (Dockerhub)](https://hub.docker.com/r/mattrayner/lamp)<br>

to run script do the following:
`git clone https://github.com/The0mikkel/auto-multicontainer-setup`
`cd auto-multicontainer-setup`
`./docker-setup.sh`

If you see following error `/bin/bash^M`
Run following command `sed -i -e 's/\r$//' docker-setup.sh && ./docker-setup.sh`

