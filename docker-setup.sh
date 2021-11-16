#!/bin/bash
# If following error is sent: /bin/bash^M - use `sed -i -e 's/\r$//' docker-setup.sh`

# import all env variables
set -o allexport
source .env
set +o allexport

# Handle flags when program is called
while getopts d: flag
do
    case "${flag}" in
        d) web_dir=${OPTARG};;
        *)
    esac
done


# Prepare and run directory set up
chmod u+x ./scripts/web-dir.sh && sed -i -e 's/\r$//' ./scripts/web-dir.sh
if ./scripts/web-dir.sh -d $web_dir ; then
    # echo -e "${GREEN}Directory correctly set up.${NC}";
    :
else
    echo -e "${RED}Failed directory creation.${NC}";
    exit;
fi
echo "---------------------------------------------------------"

# Prepare and run reverse proxy setup
chmod u+x ./scripts/nginx-reverse-proxy.sh && sed -i -e 's/\r$//' ./scripts/nginx-reverse-proxy.sh

if ./scripts/nginx-reverse-proxy.sh -d $web_dir ; then
    # echo -e "${GREEN}NGINX reverse proxy set up.${NC}";
    :
else
    echo -e "${RED}Failed NGINX reverse proxy set up.${NC}";
    exit;
fi
echo "---------------------------------------------------------"

# Run main part of code, to setup containers
chmod u+x ./scripts/main.sh && sed -i -e 's/\r$//' ./scripts/main.sh && ./scripts/main.sh