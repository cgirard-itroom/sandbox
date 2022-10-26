#!/bin/sh

apk add git bash curl
cd /tmp \
    &&  wget https://github.com/symfony-cli/symfony-cli/releases/download/v5.4.11/symfony-cli_linux_amd64.tar.gz \
    && tar -zxvf symfony-cli_linux_amd64.tar.gz \
    && mv symfony /usr/local/bin \
    && rm -rf /tmp/*

GIT_AUTHOR_NAME='IT-ROOM' EMAIL='developpement@itroom.fr' /usr/local/bin/symfony new --webapp --version=lts /tmp/new-project
rm -rf /tmp/new-project/docker-compose.*

cd /tmp/new-project || exit

# Install webpack
composer require symfony/webpack-encore-bundle

# Install grumphp
curl https://gitlab.com/-/snippets/2118653/raw/master/grumphp.yml -o grumphp.yml
composer require --dev phpstan/phpstan phpro/grumphp orm-fixtures friendsofphp/php-cs-fixer povils/phpmnd

cp -rT /tmp/new-project /app
