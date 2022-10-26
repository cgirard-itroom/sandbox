-include infra/.env infra/.env.local

MAKEFLAGS += --no-print-directory
REGISTRY   ?= $(notdir $(CURDIR))-local
TAG    := $(shell git describe --tags --abbrev=0 2> /dev/null || echo 'latest')
IMG    := ${NAME}:${TAG}
LATEST := ${NAME}:latest
COMPOSE_PROJECT_NAME := $(shell basename $(REGISTRY))

COMPOSE_FILE := infra/docker/docker-compose.yml
ifneq ("$(wildcard infra/docker/docker-compose.override.yml)","")
    COMPOSE_FILE := infra/docker/docker-compose.yml:infra/docker/docker-compose.override.yml
endif

DOCKER_COMPOSE := COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose
YARN := $(DOCKER_COMPOSE) run --rm node yarn
SYMFONY := $(DOCKER_COMPOSE) exec -T php php -d memory_limit=2G bin/console
COMPOSER := $(DOCKER_COMPOSE) exec -T php composer

export REGISTRY COMPOSE_FILE COMPOSE_PROJECT_NAME

### Docker
up: ## Démarre les containers
	$(MAKE) run cmd='rm -rf var/cache/prod'
	$(DOCKER_COMPOSE) up  -d --no-recreate nginx

stop: ## Stop les containers
	$(DOCKER_COMPOSE) stop

down: ## Supprime les containers
	$(DOCKER_COMPOSE) down

pull: login ## pull les images depuis le repository gitlab
	$(DOCKER_COMPOSE) pull

login: ## connexion au registry gitlab
	[ ! -z "$$CI_REGISTRY_IMAGE" ] || docker login registry.gitlab.com

build: ## Build les différentes images
	$(eval c := php)
	$(DOCKER_COMPOSE) build $(c)

exec: ## Connexion au container php
	$(eval c := php)
	$(eval cmd := sh)
	$(DOCKER_COMPOSE) exec  $(c) $(cmd)

run: ## Démarre un container
	$(eval c := php)
	$(eval cmd := sh)
	$(DOCKER_COMPOSE) run --rm --no-deps $(c) $(cmd)


### Environnement de développement

init: infra/docker/docker-compose.override.yml composer.json pull build assets-build up vendor fixtures fix-permissions ## Generate all

fixtures: ## Charge les fitures en base de données
	$(eval env := dev)
	$(SYMFONY) doctrine:database:drop --if-exists --force -e $(env)
	$(SYMFONY) doctrine:database:create -e $(env)
	$(SYMFONY) doctrine:migrations:migrate --no-interaction --allow-no-migration -e $(env)
	$(SYMFONY) doctrine:fixture:load --no-interaction -e $(env) || true

grumphp: ## Lance grumphp
	$(DOCKER_COMPOSE) run --rm --no-deps php ./vendor/bin/grumphp run

phpunit: ## Lance phpunit
	$(MAKE) fixtures env=test
	$(DOCKER_COMPOSE) exec -T php  php -dpcov.enabled=1 -dpcov.directory=src/ -dpcov.exclude="~vendor~" bin/phpunit   --coverage-text --colors=never


fix-permissions: ## Corrige les problèmes de permissions
	$(DOCKER_COMPOSE) exec -T php chown -R www-data var/log var/cache

vendor: ## Install les dépendances composer
	$(COMPOSER) install

migration: ## Créer un fichier de migration
	$(SYMFONY) make:migration

migrate: ## Lance les migrations
	$(SYMFONY) doctrine:migration:migrate -n


### Fronts (css/js)
yarn-install: ## Lance yarn install
	$(YARN) install

assets-build: yarn-install ## Build les assets en mode dev (mode prod : 'make assets-build env=prod')
	$(eval env := dev)
	$(YARN) encore $(env)

assets-watch: yarn-install ## Lance le mode dev avec l'option --watch
	$(YARN) encore dev --watch

composer.json:
	$(DOCKER_COMPOSE) build php
	$(DOCKER_COMPOSE) run --rm --no-deps php sh /usr/local/bin/install-symfony.sh


.PHONY: vendor help
.DEFAULT_GOAL := help
.EXPORT_ALL_VARIABLES:

destroy-all:
	sudo rm -rf assets bin config migrations node_modules public src templates tests translations var vendor .env .env.test .gitignore composer.json composer.lock package.json phpunit.xml.dist symfony.lock webpack.config.js yarn.lock grumphp.yml .php-cs-fixer.dist.php .php-cs-fixer.cache

### Divers

infra/docker/docker-compose.override.yml:
	cp infra/docker/docker-compose.override.yml.dist infra/docker/docker-compose.override.yml

registry: ## Affiche le registry docker configuré dans le makefile (utilisé par grumphp)
	@echo ${REGISTRY}

help: ## Test
	@awk 'BEGIN {FS = ":.*##";} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^###/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
