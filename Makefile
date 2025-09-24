SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
# Credits: https://tech.davis-hansson.com/p/make/

include .env

default: up

# Vars useful only in the makefile (e.g. no need to define in .env)
COMPOSER_ROOT ?= /var/www/html
DRUPAL_ROOT ?= /var/www/html/web
COMPOSE_FILES ?= -f compose.yml $(shell (echo "${TRAEFIK_DASH_ENABLE}" | grep -Eiq  "(true|yes)") && echo "-f compose.dash.yml") $(shell [ -f compose.override.yml ] && echo "-f compose.override.yml") $(shell (echo "${TLS_ENABLE}" | grep -Eiq  "(true|yes)") && echo "-f compose.tls.yml") $(shell (echo "${SSH_ENABLE}" | grep -Eiq  "(true|yes)") && echo "-f compose.ssh.yml") $(shell (echo "${IOCAINE_ENABLE}" | grep -Eiq  "(true|yes)") && echo "-f compose.iocaine.yml")
# UID/GID only used for the build of pece-disto container.
# To change execution user for php container, it must be built at a higher level.
UID ?= $(shell id -u)
GID ?= $(shell id -g)

## check	:	Output the merged composer.yml files
.PHONY: check
check:
	@echo "Compose files: $(COMPOSE_FILES)"
	docker compose $(COMPOSE_FILES) config

## compare	:	Check for new/updated values in .env.example compared to current .env file
.PHONY: compare
compare:
	echo "Looking for new/different .env entries using .env.example"
	grep -vE "^#" .env | grep -v "^$$" | sort > .env.strip
	grep -vE "^#" .env.example | grep -v "^$$" | sort > .env.example.strip
	diff -u .env.strip .env.example.strip | diffr
	rm .env.strip
	rm .env.example.strip

## update	:	Update PECE with latest available release.
.PHONY: update
update: prune
	@echo "Updating $(PROJECT_NAME)..."
	git pull origin
	make up
	make drush deploy
	@echo "Finish Install $(PROJECT_NAME)"

## prepare	:	Create files not in repository that must have alternate ownership
.PHONY: prepare
prepare:
	@echo "Creating files owned by other users (requires sudo)"
	sudo touch docker/ssh/authorized_keys
	sudo chown 82:82 docker/ssh/authorized_keys
	sudo mkdir -p docker/solr
	sudo chown 1001:1001 docker/solr

## build	:	Build PECE with latest available release.
.PHONY: build
build: pece-distro
	@echo "Build $(PROJECT_NAME)..."
	cd pece-distro && git pull origin && git checkout $(PROJECT_BRANCH) && cd -
	cp docker/wodby/drupal10.settings.php.tmpl pece-distro/
	docker build -t "pece-drupal:latest" -t "pece-drupal:$(BUILD_VERSION)" -t "pece-drupal:$(shell cd pece-distro && git describe --always --abbrev=8 HEAD)" --build-arg PHP_VER="$(PHP_VER)" --build-arg UID="$(UID)" --build-arg GID="$(GID)" -f Dockerfile ./pece-distro

.PHONY: docker-files
docker-files: docker/traefik/acme.json docker/traefik/acme-test.json docker/crontab docker/wodby/nginx-preset.conf

pece-distro:
	git clone $(PROJECT_GIT) pece-distro
	cd pece-distro && git checkout $(PROJECT_BRANCH)

docker/crontab:
	echo "*/15 * * * * drush -r /var/www/html/web cron" > docker/crontab

docker/wodby/nginx-preset.conf:
	cat $(shell (echo "${IOCAINE_ENABLE}" | grep -Eiq  "(true|yes)") && echo "docker/wodby/nginx-iocaine.conf") docker/wodby/nginx-d10.conf > docker/wodby/nginx-preset.conf

docker/traefik/acme.json docker/traefik/acme-test.json:
	touch $@
	chmod 600 $@

## push	:	Push PECE to remote registry
.PHONY: push
push:
	@echo "Pushing $(PROJECT_NAME) @ $(PECE_COMMIT)..."
	docker tag pece-drupal:latest $(REGISTRY)/pece-drupal:latest
	docker push -a "$(REGISTRY)/pece-drupal"

## help	:	Print commands help.
.PHONY: help
help : $(wildcard Makefile docker.mk)
	@sed -n 's/^##//p' $<

## up	:	Start up containers with production ssl.
.PHONY: up
up: docker-files
	@echo "Starting up containers for $(PROJECT_NAME)..."
	chmod 600 docker/traefik/acme.json
	chmod 600 docker/traefik/acme-test.json
	docker compose $(COMPOSE_FILES) up -d --remove-orphans

.PHONY: reload-config
## reload-config	:	Update the configuration for Drupal's core
reload-config:
	@echo "Updating solr configuration for drupal core - requires sudo to write files as UID 1001"
	[ -d ./docker/solr/server/solr/drupal/conf ] && sudo rm -rf ./docker/solr/server/solr/drupal/conf/* || (echo 'Drupal core does not appear to exist - check solr logs'; exit 1)
	sudo unzip solr_9.x_config.zip -d ./docker/solr/server/solr/drupal/conf/
	docker exec $(PROJECT_NAME)_solr curl "http://localhost:8983/solr/admin/cores?action=RELOAD&core=drupal"

.PHONY: mutagen
mutagen:
	mutagen-compose up

## down	:	Stop containers.
.PHONY: down
down:
	@echo "Removing containers for $(PROJECT_NAME)..."
	docker compose $(COMPOSE_FILES) down

## start	:	Start containers without updating.
.PHONY: start
start:
	@echo "Starting containers for $(PROJECT_NAME) from where you left off..."
	docker compose $(COMPOSE_FILES) start

## stop	:	Stop containers.
.PHONY: stop
stop:
	@echo "Stopping containers for $(PROJECT_NAME)..."
	docker compose $(COMPOSE_FILES) stop

## prune	:	Remove containers and their volumes.
##		You can optionally pass an argument with the service name to prune single container
##		prune mariadb	: Prune `mariadb` container and remove its volumes.
##		prune mariadb solr	: Prune `mariadb` and `solr` containers and remove their volumes.
.PHONY: prune
prune:
	@echo "Removing containers and volumes for $(PROJECT_NAME)..."
	docker compose $(COMPOSE_FILES) down -v $(filter-out $@,$(MAKECMDGOALS))

## ps	:	List running containers.
.PHONY: ps
ps:
	@docker ps --filter name='$(PROJECT_NAME)*'

## shell	:	Access `php` container via shell.
##		You can optionally pass an argument with a service name to open a shell on the specified container
.PHONY: shell
shell:
	docker exec -ti $(shell docker ps --filter name='$(PROJECT_NAME)_$(or $(filter-out $@,$(MAKECMDGOALS)), 'php')' --format "{{ .ID }}") bash

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
	docker compose $(COMPOSE_FILES) logs -f $(filter-out $@,$(MAKECMDGOALS))
