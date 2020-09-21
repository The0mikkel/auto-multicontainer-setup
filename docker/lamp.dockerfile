# FROM php:7.4-apache
FROM mattrayner/lamp:latest-1804
LABEL maintainer="me@themikkel.dk"
ARG VIRTUAL_HOST=localhost
ARG VIRTUAL_PORT=80
ARG LETSENCRYPT_HOST=localhost
ARG LETSENCRYPT_EMAIL=test@test.com
ARG ServerName=localhost
ARG GITHUBTOKEN
ARG configLink=https://raw.githubusercontent.com/The0mikkel/auto-multicontainer-setup/master/configuration/lamp
ENV VIRTUAL_HOST=$VIRTUAL_HOST
ENV VIRTUAL_PORT=$VIRTUAL_PORT
ENV LETSENCRYPT_HOST=$LETSENCRYPT_HOST
ENV LETSENCRYPT_EMAIL=$LETSENCRYPT_EMAIL
ENV ServerName=$ServerName
ENV GITHUBTOKEN=$GITHUBTOKEN
ENV configLink=$configLink

RUN apt-get update -y && apt-get upgrade -y
# Mod security - https://www.linode.com/docs/web-servers/apache-tips-and-tricks/configure-modsecurity-on-apache/
RUN apt-get install libapache2-mod-security2 libapache2-mod-evasive git curl -y ;\
mv /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf ;\
sed -i "s/SecRuleEngine DetectionOnly/SecRuleEngine On/" /etc/modsecurity/modsecurity.conf ; \
sed -i "s/SecResponseBodyAccess On/SecResponseBodyAccess Off/" /etc/modsecurity/modsecurity.conf ;
# Apache setup
RUN random=$(date +%s) ; \
curl -L -s -H "Authorization: token ${GITHUBTOKEN}" -H 'Cache-Control: no-cache' "${configLink}/security2.conf?$random" > /etc/apache2/mods-available/security2.conf ; \
curl -L -s -H "Authorization: token ${GITHUBTOKEN}" -H 'Cache-Control: no-cache' "${configLink}/evasive.conf?$random"> /etc/apache2/mods-enabled/evasive.conf ; \
curl -L -s -H "Authorization: token ${GITHUBTOKEN}" -H 'Cache-Control: no-cache' "${configLink}/default-host.conf?$random" > /etc/apache2/sites-available/000-default.conf ; \
curl -L -s -H "Authorization: token ${GITHUBTOKEN}" -H 'Cache-Control: no-cache' "${configLink}/apache2.conf?$random" > /etc/apache2/apache2.conf ; \
a2enmod security2 ; \
a2enmod evasive ; \
a2enmod headers ;\
mkdir /var/log/mod_evasive ;\
chown -R www-data:www-data /var/log/mod_evasive
# PHP setup
RUN phpVersion=$(php -v | tac -r | tail -n 1 | cut -d " " -f 2 | cut -c 1-3); \
iniLoaction=/etc/php/$phpVersion/apache2/php.ini; \
curl -L -s https://raw.githubusercontent.com/php/php-src/master/php.ini-production -o iniLoaction; \
sed -i "s/post_max_size = 10M/post_max_size = 1G/" iniLoaction; \
sed -i "s/upload_max_filesize = 10M/post_max_size = 264M/" iniLoaction;