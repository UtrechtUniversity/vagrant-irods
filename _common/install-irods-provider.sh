#!/bin/bash
# shellcheck disable=SC1090

set -e
set -o pipefail
set -u

export DEBIAN_FRONTEND=noninteractive

SETTINGSFILE=${1:-./local-repo.env}

if [ -f "$SETTINGSFILE" ]
then source "$SETTINGSFILE"
else echo "Error: settings file $SETTINGSFILE not found." && exit 1
fi

set +u
if [ -n "$PROVIDER_HOSTNAME" ]
then echo "Setting hostname ..."
     hostnamectl set-hostname "$PROVIDER_HOSTNAME"
else echo "Warning: not setting provider hostname because \$PROVIDER_HOSTNAME is undefined."
fi
set -u

if [ -f /etc/centos-release ]
then

  echo "Adding EPEL release repository ..."
  sudo yum install -y epel-release

  echo "Installing dependencies of installation script ..."
  sudo yum install -y pwgen wget yum-plugin-versionlock

  echo "Importing repository signing key ..."
  sudo rpm --import "$YUM_IRODS_REPO_SIGNING_KEY_LOC"

  echo "Updating certificates for retrieving repository key ..."
  sudo yum update -y ca-certificates

  echo "Adding iRODS repository ..."
  wget -qO - "$YUM_REPO_FILE_LOC" | sudo tee /etc/yum.repos.d/renci-irods.yum.repo

  for package in $YUM_DATABASE_PACKAGES
  do echo "Installing database package $package and its dependencies ..."
     yum -y install "$package"
  done

  for package in $YUM_PACKAGES
  do echo "Installing package $package and its dependencies ..."
     if [ "$package" == "irods-rule-engine-plugin-python" ]
     then
	 if [ "$IRODS_VERSION" == "4.2.8" ]
	 then package_version="4.2.8.0"
         elif [ "$IRODS_VERSION" == "4.2.9" ]
         then package_version="4.2.9.0"
         elif [ "$IRODS_VERSION" == "4.2.10" ]
         then package_version="4.2.10.0"
	 else package_version="$IRODS_VERSION"
	 fi
     else
	 package_version="$IRODS_VERSION"
     fi
     sudo yum -y install "$package-$package_version"
     sudo yum versionlock "$package"
  done

  echo "Initializing database ..."
  sudo postgresql-setup initdb

  echo "Configuring database authentication ..."
  sed -i 's/^host    all             all             127.0.0.1\/32            ident$/host    all             all             127.0.0.1\/32            md5/' /var/lib/pgsql/data/pg_hba.conf
  sed -i 's/^host    all             all             ::1\/128                 ident$/host    all             all             ::1\/128                 md5/' /var/lib/pgsql/data/pg_hba.conf

  echo "Starting database ..."
  sudo systemctl start postgresql
  sudo systemctl enable postgresql

elif lsb_release -i | grep -q Ubuntu
then

  echo "Downloading and installing iRODS repository signing key ..."
  wget -qO - "$APT_IRODS_REPO_SIGNING_KEY_LOC" | sudo apt-key add -

  echo "Adding iRODS repository ..."
cat << ENDAPTREPO | sudo tee /etc/apt/sources.list.d/irods.list
deb [arch=${APT_IRODS_REPO_ARCHITECTURE}] $APT_IRODS_REPO_URL $APT_IRODS_REPO_DISTRIBUTION $APT_IRODS_REPO_COMPONENT
ENDAPTREPO
  sudo apt-get update

  echo "Installing dependencies of installation script ..."
  sudo apt-get -y install aptitude pwgen

  for package in $APT_DATABASE_PACKAGES
  do echo "Installing database package $package and its dependencies ..."
     apt -y install "$package"
  done

  for package in $APT_PACKAGES
  do echo "Installing package $package and its dependencies ..."
     if [ "$package" == "irods-rule-engine-plugin-python" ]
     then
         if [ "$IRODS_VERSION" == "4.2.8" ]
         then package_version="4.2.8.0"
         elif [ "$IRODS_VERSION" == "4.2.9" ]
         then package_version="4.2.9.0"
         elif [ "$IRODS_VERSION" == "4.2.10" ]
         then package_version="4.2.10.0"
         else package_version="$IRODS_VERSION"
         fi
     else
         package_version="$IRODS_VERSION"
     fi
     sudo apt-get -y install "$package=$package_version"
     sudo aptitude hold "$package"
  done

else
  echo "Error: did not recognize distribution/image."
  exit 1
fi

set +u

if [ -z "$ZONE_KEY" ]
then ZONE_KEY=$(pwgen -N 1 -n 16)
fi

if [ -z "$NEG_KEY" ]
then NEG_KEY=$(pwgen -N 1 -n 32)
fi

if [ -z "$CP_KEY" ]
then CP_KEY=$(pwgen -N 1 -n 32)
fi

if [ -z "$DB_PASSWORD" ]
then DB_PASSWORD=$(pwgen -N 1 -n 16)
fi

set -u

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

# Restart is needed for iRODS 4.2.9+
sudo /etc/init.d/irods restart

echo "Provider install script finished."
