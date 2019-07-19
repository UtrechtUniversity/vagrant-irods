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
