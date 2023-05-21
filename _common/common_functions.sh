#!/bin/bash
function get_package_version()
{
     local package="$1"
     local IRODS_VERSION="$2"
     local distro="$3"
     if [ "$package" == "irods-rule-engine-plugin-python" ]
     then
         if [ "$IRODS_VERSION" == "4.2.8" ]
         then package_version="4.2.8.0"
         elif [ "$IRODS_VERSION" == "4.2.9" ]
         then package_version="4.2.9.0"
         elif [ "$IRODS_VERSION" == "4.2.10" ]
         then package_version="4.2.10.0"
         elif [ "$IRODS_VERSION" == "4.2.11" ] && [  "$distro" == "ubuntu" ]
         then package_version="4.2.11.1-1~xenial"
         elif [ "$IRODS_VERSION" == "4.2.12" ] && [  "$distro" == "ubuntu" ]
         then package_version="4.2.12.0-1~bionic"
         elif [ "$IRODS_VERSION" == "4.2.11" ] && [ "$distro" == "centos" ]
         then package_version="4.2.11.1"
         elif [ "$IRODS_VERSION" == "4.2.12" ] && [ "$distro" == "centos" ]
         then package_version="4.2.12.0"
         else package_version="$IRODS_VERSION"
         fi
     else
         if [ "$IRODS_VERSION" == "4.2.11" ] && [  "$distro" == "ubuntu" ]
         then package_version="4.2.11-1~xenial"
	 elif [ "$IRODS_VERSION" == "4.2.12" ] && [ "$distro" == "ubuntu" ]
	 then package_version="4.2.12-1~bionic"
         else # shellcheck disable=SC2034
              package_version="$IRODS_VERSION"
         fi
     fi
}

