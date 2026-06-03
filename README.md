# PECE Server Setup

## Introduction

This codebase contains a set of Docker compose files and utilities to manage them. The primary configuration file is the `.env` file, which includes all settings for your site. This env file is loaded into the Makefile and the included compose files to coordinate your docker stack.

Aside from the primary NGINX, PHP, and MariaDB containers, a variety of additional services are available, including:
  * traefik: the ingress controller
  * solr: for indexing search content
  * iocane: for AI bot mitigation
  * ssh: for remote access for running drush, etc
  * valkey: a Valkey for that performs in-memory caching of key-value data
  * cron: an additional container runs periodic cron tasks, by default `drush cron`

Some of these containers are entirely optional, and can be enabled/disabled via .env values.

Additionally, both Solr and Valkey require additional setup steps, so review those sections in addition to the basic setup.

## Requirements

In order to use this repository, the following tools are required:

  * git: to fetch/manage the repository content
  * make: to run various commands to manage the stack
  * [Docker](https://docker.com/): which is the container management platform
  * diffr (a diff formatter), unzip (decompressor): additional utilities used via make commands

Docker rootless and podman are untested at this time. They will likely require additional user id mapping.

## Installation & Setup

- Download/Clone this repository on your server to the desired folder. Enter that folder, and copy the .env-example to .env.

```bash
git clone https://github.com/PECE-project/pece-distro-setup.git <your-pece-instance-directory-name>
cd <your-pece-instance-directory-name>
cp .env.example .env
```

Edit your new `.env` file and set the following variables according to your needs.

## Project structure

The project is primarily a set of compose.yml files that are combined with `make` and your `.env` configuration to create a set of coordinated docker containers. All the relevant compose*.yml files are in project root. Additional paths include:

* docker: contains various additional configuration files as needed for each container. Additionally, log files and other persistent files are written beneath here:
  * backup: loaded r/w for the drupal user in order to write e.g. backup sql files
  * ~~certbot: the traefik container maintains the TLS certificates here~~
  * config: (if used) contains configuration used by drupal. Documented as it's own topic below.
  * database: mariadb databases
  * files: the web site's public files directory
  * iocaine: source documents for setting up iocaine
  * logs: contains subfolders for writing service log files
  * private: the web site's private files directory
  * solr: the solr collection/core configuration
  * ssh: key files for the ssh server
  * traefik: the server configuration file along with the TLS certificates
  * wodby: various additional customized files for the wodby containers used (drupal and nginx)
* pece-distro: the location the pece distribution is checked out and built from
* resources: additional files useful for the project, but not used by default. See the README.md in that folder.

## Building locally vs using a centralized image container registry

The make file contains commands for building, tagging, and pushing images to a shared container registry. You can either use the `make build` on each target system, or else use a common image container registry to share your builds. NOTE: The remainder of the documentation will assume the local build option is used.

When using `make build` the `BUILD_VERSION` will be used as a tag, as well as `latest` and the git hash.

The REGISTRY environment variable must be set to your target location. The registry value should include the organization, for example: `REGISTRY="git.example.com/organization"` Ensure you are logged into the container registry.

TODO: Add `make pull`

## Configuring settings (the .env file)

Nearly all options for running the set of containers on your server are supplied via the .env file in your project root (which would have been copied earlier from .env.example).

The most common configuration options will be explained here, and additional details are available as comments in the .env file itself.

```bash
DRUSH_OPTIONS_URI=http://<your-pece-instance-name.com>

### PROJECT SETTINGS
PROJECT_NAME=<your_pece_instance_name> # This determines the container names
PROJECT_BASE_URL=<your-pece-instance-name.com> # Do not include the protocol, just the DNS name.

DB_NAME=<your-pece-database-name>
DB_USER=<your-pece-database-username>
DB_PASSWORD=<put-a-strong-password-here>
DB_ROOT_PASSWORD=<put-a-strong-password-here>
```

## Drupal Configuration management

The PECE distribution maintains the full set of configuration options that set up the site. These are maintained centrally, and the default configuration will pull in any updated options when you perform an upgrade.

If you wish to manage your own configuration, you will want to get the configuration external to the container. This can be done by setting the DRUPAL_CONFIG_SYNC_DIR. This will mount the location specified, relative to the project root, into the container's /var/www/html/config folder, which PECE uses by default to load/save configuration.

```bash
DRUPAL_CONFIG_SYNC_DIR="./docker/config"
```

When this value is unset (the default), a pece_config volume will be used to house the config, and is pre-loaded from the image's standard configuration values.

## Initializing the project

In order to run this project, a few steps (varied by your extra container selections) have to be performed. These only have to be run once per install.

- `make build`: In order to build the container image locally, you can use:
- `docker network create frontend`: Creates the front-end network.
- As your DB will not exist it will not yet be configured to enable Valkey. Given this, you should not specify a Valkey host value yet. In the .env file, ensure setting "REDIS_HOST=", with nothing after the equal sign.
- `make prepare`: Creates additional folders and sets owners. This step requires sudo permission on order to set the user/group values on folders beneath `docker`
- You can now start the images using `make up`
- If using Solr, after the containers are up (check with `make ps`), you will need to add the Solr configuration for the pre-created drupal core. `make reload-config`
- Log into the php container to run your site install: `make shell` and then inside the container `drush si pece --existing-config` (you can `exit` after to exit the container)
- At this point, you can re-enable Valkey by setting the .env value `REDIS_HOST=redis`, and then restart the containers with `make up`

## Performing upgrades

Pull the latest code for configuring docker containers with `git pull`
Ensure you are not missing any newly added configuration options. `make compare` will show differences between `.env.example` and your current `.env` file
If you are building on the target system:
Set a new release tag in `.env`
If you use a common build/CI/etc:
Set your REPOSITORY and

```
make shell
$ drush sql-dump --gzip > /mnt/files/backup/pre-install.sql.gz
$ exit
git pull # get latest configuration/docker code
make compare # check for any new .env requirements and adjust
make build
make prune # ensures removal of the php code volume
make up
make shell
$ drush deploy # perform drupal updates
$ cd content/essential
$ find . -type f -exec ../../vendor/bin/drush content:import ../content/essential/{} \; # import default content items
$ exit
```

- Access http://`<your-pece-instance-name.com>` on your browser and proceed with installation of your new instance of PECE.

## Others commands
```shell
make up
```
If you need up the project only, no install.

---
```shell
make stop
```
If you need stop the project

Run `make help` to see other commands (or else refer to `Makefile`).

## Helpful information

### Checking Valkey:

You can introspect the valkey database with the following commands. This can be used to verify the valkey database is correctly being used with Drupal.

```
make shell valkey
valkey-cli
keys *
```

This should list hundreds of keys - if it does not, there is a problem with Drupal connecting to it. You can exit the valkey-cli and container shell with `exit` (twice).

## Customizing Drupal

If you are managing your own Drupal codebase, be sure to add the following at or
near the bottom of your settings.php file to load the settings passed into the
containers:

```php
if (file_exists('/var/www/conf/wodby.settings.php')) {
  include '/var/www/conf/wodby.settings.php';
}
```
