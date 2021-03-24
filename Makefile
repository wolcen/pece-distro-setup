include docker.mk

.PHONY: test build

DRUPAL_VER ?= 7
PHP_VER ?= 7.2

BRANCH = $(shell git rev-parse --abbrev-ref HEAD)

test:
	cd ./tests/$(DRUPAL_VER) && PHP_VER=$(PHP_VER) ./run.sh

install:
	@echo "Install $(PROJECT_NAME)..."
	docker-compose -f docker-compose.commands.yml up git-clone
	make up
	@echo "Finish Install $(PROJECT_NAME)"

