#!/bin/bash
# shellcheck disable=SC1090

set -e
set -u

SETTINGSFILE=${1:-./local-repo.env}
KEEPALIVE_TIME="120"
KEEPALIVE_INTVL="30"

if [ -f "$SETTINGSFILE" ]
then source "$SETTINGSFILE"
else echo "Error: settings file $SETTINGSFILE not found." && exit 1
fi

echo "$KEEPALIVE_TIME"  | sudo tee /proc/sys/net/ipv4/tcp_keepalive_time
echo "$KEEPALIVE_INTVL" | sudo tee /proc/sys/net/ipv4/tcp_keepalive_intvl

echo "net.ipv4.tcp_keepalive_time=$KEEPALIVE_TIME" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
echo "net.ipv4.tcp_keepalive_intvl=$KEEPALIVE_INTVL" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
