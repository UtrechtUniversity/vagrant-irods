#!/bin/bash

set -e
set -u

SETTINGSFILE=${1:-./local-repo.env}

if [ -f "$SETTINGSFILE" ]
then source "$SETTINGSFILE"
else echo "Error: settings file $SETTINGSFILE not found." && exit 1
fi


if [ -n "$PROVIDER_HOSTNAME" ]
then echo "$PROVIDER_IP $PROVIDER_HOSTNAME" | sudo tee -a /etc/hosts
fi

if [ -n "$CONSUMER_HOSTNAME" ]
then echo "$CONSUMER_IP $CONSUMER_HOSTNAME" | sudo tee -a /etc/hosts
fi
