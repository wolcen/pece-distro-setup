include .env

default: up

# Vars useful only in the makefile (e.g. no need to define in .env)
COMPOSER_ROOT ?= /var/www/html
DRUPAL_ROOT ?= /var/www/html/web
REGISTRY ?= git.example.com/organization
# UID/GID only used for the build of pece-disto container.
# To change execution user for php container, it must be built at a higher level.
UID ?= $(shell id -u)
GID ?= $(shell id -g)
# Determine the current hash for the latest pulled version
PECE_COMMIT=$(shell cd pece-distro && git describe --always --abbrev=8 HEAD)

## update	:	Update PECE with latest available release.
.PHONY: update
update:
	@echo "Update $(PROJECT_NAME)..."
	make down
	git pull origin
	make up
	make drush deploy
	@echo "Finish Install $(PROJECT_NAME)"

## no-ssl-up	:	Start up containers without ssl.
.PHONY: no-ssl-up
no-ssl-up: docker/traefik/acme.json docker/traefik/acme-test.json
	@echo "Starting up containers for $(PROJECT_NAME) without ssl"
	docker compose up -d --remove-orphans

## build	:	Build PECE with latest available release.
.PHONY: build
build: pece-distro
	@echo "Build $(PROJECT_NAME)..."
	cd pece-distro && git pull origin && git checkout $(PROJECT_BRANCH)
	docker build -t "pece-drupal:latest" -t "pece-drupal:$(PECE_COMMIT)" --build-arg PHP_VER="$(PHP_TAG)" --build-arg UID="$(UID)" --build-arg GID="$(GID)" -f Dockerfile ./pece-distro
	
pece-distro:
	git clone $(PROJECT_GIT) pece-distro
	cd pece-distro && git checkout $(PROJECT_BRANCH)

docker/traefik/acme.json docker/traefik/acme-test.json:
	touch $@
	chmod 600 $@

## push	:	Push PECE to remote registry
.PHONY: push
push:
	@echo "Pushing $(PROJECT_NAME) @ $(PECE_COMMIT)..."
	docker tag pece-drupal:latest $(REGISTRY)/pece-drupal:latest
	docker push "$(REGISTRY)/pece-drupal:latest" -a

## help	:	Print commands help.
.PHONY: help
help : $(wildcard Makefile docker.mk)
	@sed -n 's/^##//p' $<

## up	:	Start up containers with production ssl.
.PHONY: up
up: docker/traefik/acme.json docker/traefik/acme-test.json
	@echo "Starting up containers for $(PROJECT_NAME)..."
	chmod 600 docker/traefik/acme.json
	chmod 600 docker/traefik/acme-test.json
	docker compose -f compose.yml -f compose.ssl.yml up -d --remove-orphans

.PHONY: mutagen
mutagen:
	mutagen-compose up

## down	:	Stop containers.
.PHONY: down
down: stop

## start	:	Start containers without updating.
.PHONY: start
start:
	@echo "Starting containers for $(PROJECT_NAME) from where you left off..."
	@docker compose start

## stop	:	Stop containers.
.PHONY: stop
stop:
	@echo "Stopping containers for $(PROJECT_NAME)..."
	@docker compose stop

## prune	:	Remove containers and their volumes.
##		You can optionally pass an argument with the service name to prune single container
##		prune mariadb	: Prune `mariadb` container and remove its volumes.
##		prune mariadb solr	: Prune `mariadb` and `solr` containers and remove their volumes.
.PHONY: prune
prune:
	@echo "Removing containers for $(PROJECT_NAME)..."
	@docker compose down -v $(filter-out $@,$(MAKECMDGOALS))

## ps	:	List running containers.
.PHONY: ps
ps:
	@docker ps --filter name='$(PROJECT_NAME)*'

## shell	:	Access `php` container via shell.
##		You can optionally pass an argument with a service name to open a shell on the specified container
.PHONY: shell
shell:
	docker exec -ti -e COLUMNS=$(shell tput cols) -e LINES=$(shell tput lines) $(shell docker ps --filter name='$(PROJECT_NAME)_$(or $(filter-out $@,$(MAKECMDGOALS)), 'php')' --format "{{ .ID }}") sh

## composer	:	Executes `composer` command in a specified `COMPOSER_ROOT` directory (default is `/var/www/html`).
##		To use "--flag" arguments include them in quotation marks.
##		For example: make composer "update drupal/core --with-dependencies"
.PHONY: composer
composer:
	docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") composer --working-dir=$(COMPOSER_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## drush	:	Executes `drush` command in a specified `DRUPAL_ROOT` directory (default is `/var/www/html/web`).
##		To use "--flag" arguments include them in quotation marks.
##		For example: make drush "watchdog:show --type=cron"
.PHONY: drush
drush:
	docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") drush -r $(DRUPAL_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## logs	:	View containers logs.
##		You can optinally pass an argument with the service name to limit logs
##		logs php	: View `php` container logs.
##		logs nginx php	: View `nginx` and `php` containers logs.
.PHONY: logs
logs:
	@docker compose logs -f $(filter-out $@,$(MAKECMDGOALS))
