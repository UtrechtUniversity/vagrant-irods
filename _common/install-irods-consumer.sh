#!/bin/bash
# shellcheck disable=SC1090

set -e
set -o pipefail
set -u
set -x

configure_consumer_4dot2 () {
        # Test configuration has been adapted from:
        # https ://github.com/irods/irods/blob/4-2-stable/plugins/database/packaging/localhost_setup_postgres.input
        sudo python /var/lib/irods/scripts/setup_irods.py <<- IRODS_SETUP_END
	vagrant
	vagrant
	0
	consumer
	$ZONE_NAME
	$PROVIDER_HOSTNAME
	1247
	20000
	20199
	1248
	
	rods
	
	$ZONE_KEY
	$NEG_KEY
	$CP_KEY
	rods
	/var/lib/irods/Vault
	IRODS_SETUP_END
}

configure_consumer_4dot3 () {
        export PROVIDER_HOSTNAME CONSUMER_HOSTNAME ZONE_NAME ZONE_KEY NEG_KEY CP_KEY ADMIN_PASSWORD
        envsubst < /tmp/consumer-unattended-install.irods-4.3.template > /tmp/consumer-unattended-install.irods-4.3.config
        sudo python3 /var/lib/irods/scripts/setup_irods.py --json_configuration_file /tmp/consumer-unattended-install.irods-4.3.config
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
if [ -n "$CONSUMER_HOSTNAME" ]
then echo "Setting hostname ..."
     hostnamectl set-hostname "$CONSUMER_HOSTNAME"
else echo "Warning: not setting provider hostname because \$CONSUMER_HOSTNAME is undefined."
fi
set -u

if [ -f /etc/centos-release ]
then

  echo "Adding EPEL release repository ..."
  sudo yum install -y epel-release

  echo "Installing dependencies of installation script ..."
  sudo yum install -y pwgen wget yum-plugin-versionlock

  echo "Importing repository signing key .."
  sudo rpm --import "$YUM_IRODS_REPO_SIGNING_KEY_LOC"

  echo "Updating certificates for retrieving repository key ..."
  sudo yum update -y ca-certificates

  echo "Adding iRODS repository ..."
  wget -qO - "$YUM_REPO_FILE_LOC" | sudo tee /etc/yum.repos.d/renci-irods.yum.repo

  echo "Installing package dependencies of install-irods script ..."
  sudo yum install -y pwgen nmap

  for package in $YUM_PACKAGES
  do echo "Installing package $package and its dependencies ..."
     get_package_version "$package" "$IRODS_VERSION" "centos"
     # $package_version is set by sourced function
     # shellcheck disable=SC2154
     sudo yum -y install "$package-$package_version"
     sudo yum versionlock "$package"
  done

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

  echo "Adding iRODS repository ..."
cat << ENDAPTREPO | sudo tee /etc/apt/sources.list.d/irods.list
deb [arch=${APT_IRODS_REPO_ARCHITECTURE}] $APT_IRODS_REPO_URL $APT_IRODS_REPO_DISTRIBUTION $APT_IRODS_REPO_COMPONENT
ENDAPTREPO
  sudo apt-get update

  if [[ "$IRODS_VERSION" =~ ^4\.3\. ]]
  then sudo apt -y install python3-pyodbc
  else sudo apt -y install python-pyodbc
  fi

  echo "Installing dependencies of installation script ..."
  sudo apt-get install -y pwgen nmap aptitude python3-pip

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

set -u

# Wait until the provider has started
PROVIDER_READY="no"
for try in $(seq 1 100)
do if nmap -p 1247 "$PROVIDER_HOSTNAME" | grep -q open
   then PROVIDER_READY="yes"
        break
   fi
   echo "Waiting for provider to be ready (try $try) ..."
   sleep 1
done

if [ "$PROVIDER_READY" != "yes" ]
then echo "Provider was not ready in time."
     exit 1
fi

if [[ "$IRODS_VERSION" =~ ^4\.2\. ]]
then echo "Setting up iRODS 4.2 on consumer."
     configure_consumer_4dot2
elif [[ "$IRODS_VERSION" =~ ^4\.3\. ]]
then echo "Setting up iRODS 4.3 on consumer."
     configure_consumer_4dot3
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


echo "Consumer install script finished."
