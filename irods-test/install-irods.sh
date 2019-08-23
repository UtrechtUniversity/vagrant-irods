#!/bin/bash

set -e
set -o pipefail
set -u

export DEBIAN_FRONTEND=noninteractive

SETTINGSFILE=${1:-./local-repo.env}

if [ -f "$SETTINGSFILE" ]
then source "$SETTINGSFILE"
else echo "Error: settings file $SETTINGSFILE not found." && exit 1
fi

if [ -f /etc/centos-release ]
then

  echo "Adding EPEL release repository ..."
  sudo yum install -y epel-release

  echo "Installing package dependencies of install-irods script ..."
  sudo yum install -y pwgen wget

  echo "Importing repository signing key .."
  sudo rpm --import "$YUM_IRODS_REPO_SIGNING_KEY_LOC"

  echo "Adding iRODS repository ..."
  wget -qO - "$YUM_REPO_FILE_LOC" | sudo tee /etc/yum.repos.d/renci-irods.yum.repo

  echo "Installing package dependencies of install-irods script ..."
  sudo yum install -y pwgen

  for package in $YUM_PACKAGES
  do echo "Installing package $package and its dependencies"
     sudo yum -y install "$package"
  done

  echo "Initializing database ..."
  sudo postgresql-setup initdb

  echo "Configuring database authentication ..."
  sed -i 's/^host    all             all             127.0.0.1\/32            ident$/host    all             all             127.0.0.1\/32            md5/' /var/lib/pgsql/data/pg_hba.conf
  sed -i 's/^host    all             all             ::1\/128                 ident$/host    all             all             ::1\/128                 md5/' /var/lib/pgsql/data/pg_hba.conf

  echo "Starting database ..."
  sudo systemctl start postgresql

elif lsb_release -i | grep -q Ubuntu
then

  echo "Downloading and installing iRODS repository signing key ..."
  wget -qO - "$APT_IRODS_REPO_SIGNING_KEY_LOC" | sudo apt-key add -

  echo "Adding iRODS repository ..."
cat << ENDAPTREPO | sudo tee /etc/apt/sources.list.d/irods.list
deb [arch=${APT_IRODS_REPO_ARCHITECTURE}] $APT_IRODS_REPO_URL $APT_IRODS_REPO_DISTRIBUTION $APT_IRODS_REPO_COMPONENT
ENDAPTREPO
  sudo apt-get update

  for package in $APT_PACKAGES
  do echo "Installing package $package and its dependencies"
     sudo apt-get -y install "$package"
  done

  echo "Installing package dependencies of install-irods script ..."
  sudo apt-get install -y pwgen


else
  echo "Error: did not recognize distribution/image."
  exit 1
fi

ZONE_KEY=$(pwgen -N 1 -n 16)
NEG_KEY=$(pwgen -N 1 -n 32)
CP_KEY=$(pwgen -N 1 -n 32)
DB_PASSWORD=$(pwgen -N 1 -n 16)

sudo -u postgres psql <<PSQL_END
CREATE USER irods WITH PASSWORD '$DB_PASSWORD';
CREATE DATABASE "ICAT";
GRANT ALL PRIVILEGES ON DATABASE "ICAT" TO irods;
\q
PSQL_END

# Test configuration has been adapted from:
# https://github.com/irods/irods/blob/4-2-stable/plugins/database/packaging/localhost_setup_postgres.input
sudo python /var/lib/irods/scripts/setup_irods.py << IRODS_SETUP_END
vagrant
vagrant


localhost
5432
ICAT
irods
y
$DB_PASSWORD

testZone
1247
20000
20199
1248

rods
y
$ZONE_KEY
$NEG_KEY
$CP_KEY
rods


IRODS_SETUP_END
