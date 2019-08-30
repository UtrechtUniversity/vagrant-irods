# vagrant-irods

This repository contains Vagrant configurations for local iRODS VMs.

# Prerequisites

You'll need [VirtualBox](https://www.virtualbox.org/wiki/Downloads), as well as [Vagrant 2.x](https://www.vagrantup.com/downloads.html) with the vagrant-env plugin. Install the plugin with:  _vagrant plugin install vagrant-env_

# Included configurations

- irods-single-server: a basic plain vanilla iRODS server for local testing. It can run on either a CentOS 7 image or a Ubuntu 18.04 LTS image.
- irods-provider-consumer: an iRODS zone consisting of a provider and a single consumer. It can run on either a CentOS 7 image or a Ubuntu 18.04 LTS image. The VMs are meant for local testing, and run with default key values.
- irods-icommands: a VM which contains the icommands tools for remote administration of iRODS. It can run on either a CentOS 7 image or a Ubuntu 18.04 LTS image.

# Usage

- Go to the configuration directory.
- Optionally adjust the settings in the .env file. You might want to change the image of the VM or the amount of memory assigned to the VM.
- _vagrant up_
