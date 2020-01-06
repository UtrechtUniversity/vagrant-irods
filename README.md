# vagrant-irods

This repository contains Vagrant configurations for local iRODS VMs.

# Prerequisites

* Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* Install [Vagrant 2.x](https://www.vagrantup.com/downloads.html)
* Install the vagrant-env plugin:  _vagrant plugin install vagrant-env_

# Included configurations

- irods-single-server: a basic plain vanilla iRODS server for local testing. It can run on either a CentOS 7 image or a Ubuntu 18.04 LTS image.
- irods-provider-consumer: an iRODS zone consisting of a provider and a single consumer. It can run on either a CentOS 7 image or a Ubuntu 18.04 LTS image. The VMs are meant for local testing, and run with default key values.
- irods-icommands: a VM which contains the icommands tools for remote administration of iRODS. It can run on either a CentOS 7 image or a Ubuntu 18.04 LTS image.

These scripts should support the 4.2.x iRODS versions that are available through the package repositories. As of 6 January 2020, versions 4.2.2 through 4.2.7 are available
in the repositories.

# Usage

- If you use Windows, ensure that core.autocrlf is set to false in your git client before you clone the Vagrant-irods
  repository: _git config --global core.autocrlf false_
- Clone the vagrant-irods repository: _git clone https://github.com/utrechtuniversity/vagrant-irods.git_
- Go to the configuration directory. For example : _cd vagrant-irods/irods-single-server_
- Optionally adjust the settings in the .env file. You might want to change the image of the VM, the amount of memory assigned to the VM or the iRODS version to be installed.
- Start and provision the VM(s): _vagrant up_
- After the VM is provisioned, you should be able to log in using _vagrant ssh_. In case of the provider-consumer setup, use _vagrant ssh provider_ or _vagrant ssh consumer_.
