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

sudo sysctl -w "net.ipv6.conf.default.disable_ipv6=${IPV6_DISABLE}"
sudo sysctl -w "net.ipv6.conf.all.disable_ipv6=${IPV6_DISABLE}"

if [ -f /etc/centos-release ]
then
    SYSCTLCONF="/etc/sysctl.d/50-disable-ipv6.conf"
    echo "net.ipv6.conf.default.disable_ipv6=${IPV6_DISABLE}" | sudo tee -a "$SYSCTLCONF"
    echo "net.ipv6.conf.all.disable_ipv6=${IPV6_DISABLE}" | sudo tee -a "$SYSCTLCONF" 

    if [ "${IPV6_DISABLE}" == 1 ]
    then echo "ip_resolve=4" | sudo tee -a /etc/yum.conf
    fi

elif lsb_release -i | grep -q Ubuntu >& /dev/null
then
    # Need to disable IPv6 via Grub on Ubuntu, because values in
    # sysctl.conf are not applied after reboot.
    if [ "$IPV6_DISABLE" -eq "1" ]
    then sudo perl -pi.bak -e \
            's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="ipv6.disable=1"/' \
            /etc/default/grub
         sudo update-grub
    fi  
else
  echo "Error: did not recognize distribution/image."
  exit 1
fi
