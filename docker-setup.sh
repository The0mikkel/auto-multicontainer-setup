#!/bin/bash
# If following error is sent: /bin/bash^M - use sed -i -e 's/\r$//' docker-setup.sh 

# Setup webdir folder
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

chmod u+x ./scripts/web-dir.sh && sed -i -e 's/\r$//' ./scripts/web-dir.sh

if ./scripts/web-dir.sh -d $web_dir ; then
    echo -e "${GREEN}Directory correctly set up.${NC}";
else
    echo -e "${RED}Failed directory creation.${NC}";
    exit;
fi

# Setup nginx reverse proxy
chmod u+x ./scripts/nginx-reverse-proxy.sh && sed -i -e 's/\r$//' ./scripts/nginx-reverse-proxy.sh

if ./scripts/nginx-reverse-proxy.sh -d $web_dir ; then
    echo -e "${GREEN}NGINX reverse proxy set up.${NC}";
    exit;
else
    echo "${RED}Failed NGINX reverse proxy set up.${NC}";
    exit;

fi

chmod u+x ./scripts/main.sh && sed -i -e 's/\r$//' ./scripts/main.sh && ./scripts/main.sh