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

# shellcheck disable=SC1091
source /tmp/common_functions.sh

if [ -f /etc/centos-release ]
then 

  echo "Installing irods-commands on CentOS."

  echo "Installing dependencies ..."
  sudo yum -y install wget epel-release yum-plugin-versionlock

  echo "Updating certificates for retrieving repository key ..."
  sudo yum update -y ca-certificates
  
  echo "Adding iRODS repository ..."
  sudo rpm --import https://packages.irods.org/irods-signing-key.asc
  wget -qO - https://packages.irods.org/renci-irods.yum.repo | sudo tee /etc/yum.repos.d/renci-irods.yum.repo

  for package in $YUM_PACKAGES
  do echo "Installing package $package and its dependencies"
     get_package_version "$package" "$IRODS_VERSION" "centos"
     # shellcheck disable=SC2154
     sudo yum -y install "$package-${package_version}"
     sudo yum versionlock "$package"
  done 

elif lsb_release -i | grep -q Ubuntu
then

  echo "Installing irods-commands on Ubuntu."

  echo "Downloading and installing iRODS repository signing key ..."
  wget -qO - "$APT_IRODS_REPO_SIGNING_KEY_LOC" | sudo apt-key add -

  echo "Adding iRODS repository ..."
  if [ "$IRODS_VERSION" == "4.2.12" ]
  then APT_IRODS_REPO_DISTRIBUTION="bionic"
  elif [[ "$IRODS_VERSION" =~ ^4\.2\. ]]
  then APT_IRODS_REPO_DISTRIBUTION="xenial"
  else APT_IRODS_REPO_DISTRIBUTION="focal"
  fi

cat << ENDAPTREPO | sudo tee /etc/apt/sources.list.d/irods.list
deb [arch=${APT_IRODS_REPO_ARCHITECTURE}] $APT_IRODS_REPO_URL $APT_IRODS_REPO_DISTRIBUTION $APT_IRODS_REPO_COMPONENT
ENDAPTREPO

  sudo apt-get update

  echo "Installing dependencies ..."
  sudo apt-get -y install aptitude

  RELEASE=$(lsb_release -r | cut -d ":" -f 2| xargs)

  if [ "$RELEASE" == "20.04" ] && [ "$IRODS_VERSION" == "4.2.12" ]
  then echo "Running specific install steps for Ubuntu 20.04 LTS in combination with iRODS 4.2.12"
       install_focal_4dot2_base_reqs
       echo "End of specific install steps for Ubuntu 20.04 LTS in combination with iRODS 4.2.12"
  fi

  for package in $APT_PACKAGES
  do echo "Installing package $package and its dependencies"
     get_package_version "$package" "$IRODS_VERSION" "ubuntu"
     sudo apt-get -y install "$package=${package_version}"
     sudo aptitude hold "$package"
  done

else
  echo "Error: install script is not suitable for this box."

fi
