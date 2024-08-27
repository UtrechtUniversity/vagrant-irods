#!/bin/bash
# shellcheck disable=SC1090

set -e
set -o pipefail
set -u
set -x

configure_provider_4dot2 () {
	# Test configuration has been adapted from:
	# https	://github.com/irods/irods/blob/4-2-stable/plugins/database/packaging/localhost_setup_postgres.input
	sudo python /var/lib/irods/scripts/setup_irods.py <<- IRODS_SETUP_END
	vagrant
	vagrant
	
	
	localhost
	5432
	ICAT
	irods
	y
	$DB_PASSWORD
	
	$ZONE_NAME
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
}

configure_provider_4dot3 () {
	export PROVIDER_HOSTNAME DB_PASSWORD ZONE_NAME ZONE_KEY NEG_KEY CP_KEY ADMIN_PASSWORD
	envsubst < /tmp/provider-unattended-install.irods-4.3.template > /tmp/provider-unattended-install.irods-4.3.config
	sudo python3 /var/lib/irods/scripts/setup_irods.py --json_configuration_file /tmp/provider-unattended-install.irods-4.3.config
}

export DEBIAN_FRONTEND=noninteractive

SETTINGSFILE=${1:-./local-repo.env}

if [ -f "$SETTINGSFILE" ]
then source "$SETTINGSFILE"
else echo "Error: settings file $SETTINGSFILE not found." && exit 1
fi

# shellcheck disable=SC1091
source /tmp/common_functions.sh

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
     get_package_version "$package" "$IRODS_VERSION" "centos"
     # $package_version is set by sourced function
     # shellcheck disable=SC2154
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

  if [[ "$IRODS_VERSION" =~ ^4\.3\. ]]
  then sudo yum -y install gcc gcc-c++ python36-devel unixODBC-devel
       sudo python3 -m pip install pyodbc
  fi

elif lsb_release -i | grep -q Ubuntu
then

  if [ "$IRODS_VERSION" == "4.2.12" ]
  then APT_IRODS_REPO_DISTRIBUTION="bionic"
  elif [[ "$IRODS_VERSION" =~ ^4\.2\. ]]
  then APT_IRODS_REPO_DISTRIBUTION="xenial"
  else APT_IRODS_REPO_DISTRIBUTION="focal"
  fi

  echo "Downloading and installing iRODS repository signing key ..."
  wget -qO - "$APT_IRODS_REPO_SIGNING_KEY_LOC" | sudo apt-key add -

cat << ENDAPTREPO | sudo tee /etc/apt/sources.list.d/irods.list
deb [arch=${APT_IRODS_REPO_ARCHITECTURE}] $APT_IRODS_REPO_URL $APT_IRODS_REPO_DISTRIBUTION $APT_IRODS_REPO_COMPONENT
ENDAPTREPO
  sudo apt-get update

  RELEASE=$(lsb_release -r | cut -d ":" -f 2| xargs)
  PYODBC_INSTALLED="NO"

  if [ "$RELEASE" == "20.04" ] && [ "$IRODS_VERSION" == "4.2.12" ]
  then echo "Running specific install steps for Ubuntu 20.04 LTS in combination with iRODS 4.2.12"
       install_focal_4dot2_base_reqs
       install_focal_4dot2_server_reqs
       PYODBC_INSTALLED="YES"
       echo "End of specific install steps for Ubuntu 20.04 LTS in combination with iRODS 4.2.12"
  fi

  if [[ "$PYODBC_INSTALLED" == "NO" ]]
  then
       if [[ "$IRODS_VERSION" =~ ^4\.3\. ]]
       then sudo apt -y install python3-pyodbc
       else sudo apt -y install python-pyodbc
       fi
  fi

  echo "Installing dependencies of installation script and misc dependencies ..."
  sudo apt-get update
  sudo apt-get -y install aptitude pwgen python3-pip

  for package in $APT_DATABASE_PACKAGES
  do echo "Installing database package $package and its dependencies ..."
     apt -y install "$package"
  done

  for package in $APT_PACKAGES
  do echo "Installing package $package and its dependencies ..."
     get_package_version "$package" "$IRODS_VERSION" "ubuntu"
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

if [ -z "$ADMIN_PASSWORD" ]
then ADMIN_PASSWORD=$(pwgen -N 1 -n 16)
fi

set -u

sudo -u postgres psql <<PSQL_END
CREATE USER irods WITH PASSWORD '$DB_PASSWORD';
CREATE DATABASE "ICAT";
GRANT ALL PRIVILEGES ON DATABASE "ICAT" TO irods;
\q
PSQL_END

if [[ "$IRODS_VERSION" =~ ^4\.2\. ]]
then echo "Setting up iRODS 4.2 on provider."
     configure_provider_4dot2
elif [[ "$IRODS_VERSION" =~ ^4\.3\. ]]
then echo "Setting up iRODS 4.3 on provider."
     configure_provider_4dot3
     sudo install -m 0644 -o root -g root /tmp/irods.logrotate /etc/logrotate.d/irods
     sudo install -m 0644 -o root -g root /tmp/irods.rsyslog /etc/rsyslog.d/00-irods.conf
     sudo mkdir /var/log/irods
     sudo chown syslog:adm /var/log/irods
     sudo systemctl restart rsyslog.service
else echo "Configuring iRODS version $IRODS_VERSION has not been implemented."
     exit 1
fi

# Restart is needed for iRODS 4.2.9+
if [[ "$IRODS_VERSION" =~ ^4\.2\. ]]
then sudo /etc/init.d/irods restart
else sudo systemctl restart irods
fi

echo "Provider install script finished."
