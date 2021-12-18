#!/bin/bash
function get_package_version()
{
     local package="$1"
     local IRODS_VERSION="$2"
     if [ "$package" == "irods-rule-engine-plugin-python" ]
     then
         if [ "$IRODS_VERSION" == "4.2.8" ]
         then package_version="4.2.8.0"
         elif [ "$IRODS_VERSION" == "4.2.9" ]
         then package_version="4.2.9.0"
         elif [ "$IRODS_VERSION" == "4.2.10" ]
         then package_version="4.2.10.0"
         else package_version="$IRODS_VERSION"
         fi
     else
         # shellcheck disable=SC2034
         package_version="$IRODS_VERSION"
     fi
}

