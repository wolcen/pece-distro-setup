# PECE Server Setup Automation

NOTE: This branch is not yet ready for production use. Feel free to use if you can troubleshoot things.

You'll want to have some understanding of make, docker compose, docker, and possibly more.

The aim is to make this simple enough for less technical people to use, but while it works, it's not quite
there yet, and some steps may not be clearly documented.


Automate server setup for new instances of PECE using Docker and Docker-Compose.

---------------------

## Requirements
  * git, make, diffr, unzip
  * [Docker](https://docker.com/)

## Installation & Setup

- Download/Clone this repository on your server to the desired folder

```bash
git clone https://github.com/PECE-project/pece-distro-setup.git <your-pece-instance-directory-name>
```

- Enter `<your-pece-instance-directory-name>` directory: 

```bash
cd <your-pece-instance-directory-name>
```

- Copy `.env.example` file and rename it to `.env`

- Edit your new `.env` file and set the following variables according to your needs.

REVIEW SECTION/SETTINGS - needs improvement

Ex.: 

```bash
DRUSH_OPTIONS_URI=http://<your-pece-instance-name.com>

### PROJECT SETTINGS

PROJECT_NAME=<your_pece_instance_name>
PROJECT_BASE_URL=<your-pece-instance-name.com>

DB_NAME=<your-pece-database-name>
DB_USER=<your-pece-database-username>
DB_PASSWORD=<put-a-strong-password-here>
DB_ROOT_PASSWORD=<put-a-strong-password-here>
```

- In order to build the container image locally, you can use:

```
make build
```

- First run steps:

- Create the front-end network with `docker network create frontend`
- As your DB will not exist it will not yet be configured to enable Redis. Given this, you should not specify a redis host value yet. In the .env file, ensure setting "REDIS_HOST=", with nothing after the equal sign.
- You can now start the images using `make up`
- After starting the images, you will need to add the Solr configuration for the created drupal core. `make reload-config`
- Log into the php container to run your site install: `make shell` and then `drush si pece --existing-config`
- At this point, you can re-enable redis, setting the .env value `REDIS_HOST=redis`, and restart the containers with `make up`

# Checking REDIS use:

```
make shell valkey
redis-cli
keys *
```



- Then to start it, run:

```
make up
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

---
```shell
make update
```
If you need update project with new version

---
```shell
make cert
```
If you need to generate a SSL certificate

See Makefile and docker.mk to see others commands.
