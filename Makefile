include docker.mk

DRUPAL_VER ?= 8
PHP_VER ?= 8.2

BRANCH = $(shell git rev-parse --abbrev-ref HEAD)

## test	:	Run automated tests.
.PHONY: test
test:
	cd ./tests/$(DRUPAL_VER) && PHP_VER=$(PHP_VER) ./run.sh

## install	:	Install PECE.
.PHONY: install
install:
	@echo "Install $(PROJECT_NAME)..."
	docker-compose -f docker-compose.commands.yml up git-clone
	make up
	@echo "Finish Install $(PROJECT_NAME)"

## update	:	Update PECE with latest available release.
.PHONY: update
update:
	@echo "Update $(PROJECT_NAME)..."
	docker-compose -f docker-compose.commands.yml up -d update-project
	docker-compose -f docker-compose.commands.yml exec update-project git pull origin master
	docker-compose -f docker-compose.commands.yml exec update-project drush updb -y
	docker-compose -f docker-compose.commands.yml stop update-project
	@echo "Finish Install $(PROJECT_NAME)"

## no-ssl-up	:	Start up containers without ssl.
.PHONY: no-ssl-up
no-ssl-up:
	@echo "Starting up containers for $(PROJECT_NAME) without ssl"
	docker-compose pull
	docker-compose up -d --remove-orphans

