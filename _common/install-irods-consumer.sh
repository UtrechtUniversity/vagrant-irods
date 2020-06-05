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

  echo "Adding iRODS repository ..."
  wget -qO - "$YUM_REPO_FILE_LOC" | sudo tee /etc/yum.repos.d/renci-irods.yum.repo

  echo "Installing package dependencies of install-irods script ..."
  sudo yum install -y pwgen nmap

  for package in $YUM_PACKAGES
  do echo "Installing package $package and its dependencies ..."
     if [ "$package" == "irods-rule-engine-plugin-python" ]
     then
         if [ "$IRODS_VERSION" == "4.2.8" ]
         then package_version="4.2.8.0"
         else package_version="$IRODS_VERSION"
         fi
     else
         package_version="$IRODS_VERSION"
     fi
     sudo yum -y install "$package-$package_version"
     sudo yum versionlock "$package"
  done

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
  sudo apt-get install -y pwgen nmap aptitude

  for package in $APT_PACKAGES
  do echo "Installing package $package and its dependencies ..."
     if [ "$package" == "irods-rule-engine-plugin-python" ]
     then
         if [ "$IRODS_VERSION" == "4.2.8" ]
         then package_version="4.2.8.0"
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

sudo python /var/lib/irods/scripts/setup_irods.py << IRODS_SETUP_END
vagrant
vagrant
0
consumer
testZone
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
