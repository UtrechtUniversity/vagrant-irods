# vagrant-irods

This repository contains Vagrant configurations for local iRODS VMs.

# Prerequisites

You'll need [VirtualBox](https://www.virtualbox.org/wiki/Downloads), as well as [Vagrant 2.x](https://www.vagrantup.com/downloads.html) with the vagrant-env plugin. Install the plugin with:  _vagrant plugin install vagrant-env_

# Included configurations

- irods-test: a basic plain vanilla iRODS server for local testing. It can run on either a CentOS 7 image or on a Ubuntu 18.04 LTS image.
- irods-icommands: a VM which contains the icommands tools for remote administration of iRODS. It can run on either a CentOS 7 image or on a Ubuntu 18.04 LTS image.
