# vagrant-irods

This repository contains Vagrant configurations for local iRODS VMs.

# Prerequisites

* Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads), or alternatively use Libvirt with KVM
* Install [Vagrant 2.x](https://www.vagrantup.com/downloads.html)
* Install plugins depending on the provider:
  - For VirtualBox, install the vagrant-env and vagrant-disksize plugin:  _vagrant plugin install vagrant-env vagrant-disksize_
  - For Libvirt, install only the vagrant-env plugin:  _vagrant plugin install vagrant-env_ (since the disksize plugin is incompatible with the Libvirt provider)

* You may need to update your Vagrant libvirt plugin if it's old, e.g.: _vagrant plugin install vagrant-libvirt --plugin-version 0.12.2_

# Included configurations

- irods-single-server: a basic plain vanilla iRODS server for local testing.
- irods-provider-consumer: an iRODS zone consisting of a provider and a single consumer. The VMs are meant for local testing, and run with default key values.
- irods-icommands: a VM which contains the icommands tools for remote administration of iRODS.

These scripts should support the 4.2.x and 4.3.x iRODS versions that are available through the package repositories. As of 5 March 2025, versions 4.2.2 through 4.2.12, as well as 4.3.0 through 4.3.4, are available in the repositories.

The following distributions are supported:
- iRODS 4.2.x: Ubuntu 18.04 LTS (bionic)
- iRODS 4.2.12 and 4.3.x: Ubuntu 20.04 LTS (focal)
- iRODS 4.3.4 and up: Ubuntu 24.04 LTS (noble)

# Usage

- If you use Windows, ensure that core.autocrlf is set to false in your git client before you clone the Vagrant-irods
  repository: _git config --global core.autocrlf false_
- Clone the vagrant-irods repository: _git clone https://github.com/utrechtuniversity/vagrant-irods.git_
- Go to the configuration directory. For example : _cd vagrant-irods/irods-single-server_
- Optionally adjust the settings in the .env file. You might want to change the image of the VM, the amount of memory assigned to the VM or the iRODS version to be installed.
- If you want to use Libvirt rather than VirtualBox, change the Vagrant default provider: _export VAGRANT_DEFAULT_PROVIDER=libvirt_
- Start and provision the VM(s): _vagrant up_
- After the VM is provisioned, you should be able to log in using _vagrant ssh_. In case of the provider-consumer setup, use _vagrant ssh provider_ or _vagrant ssh consumer_.
