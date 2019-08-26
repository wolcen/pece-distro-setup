# PECE Server Setup Automation

Automate server setup for new instances of PECE using Docker and Docker-Compose.

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

- Run the following command to install and start all services required for you PECE instance and go grab a tea/coffee because it might take some time.

```bash
make up
```

- Download/Clone [PECE Distribution](https://github.com/PECE-project/pece-distro) into a new dir named `web` by running the following:

```bash
git clone https://github.com/PECE-project/pece-distro.git web
```
- Access http://`<your-pece-instance-name.com>` on your browser and proceed with installation of your new instance of PECE.
