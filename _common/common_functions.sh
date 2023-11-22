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
         elif [ "$IRODS_VERSION" == "4.3.0" ] && [  "$distro" == "ubuntu" ]
         then package_version="4.3.0.0-1~focal"
         elif [ "$IRODS_VERSION" == "4.3.0" ] && [ "$distro" == "centos" ]
         then package_version="4.3.0.0"
         elif [ "$IRODS_VERSION" == "4.3.1" ] && [  "$distro" == "ubuntu" ]
         then package_version="4.3.1.0-0~focal"
         elif [ "$IRODS_VERSION" == "4.3.1" ] && [ "$distro" == "centos" ]
         then package_version="4.3.1.0"
         else package_version="$IRODS_VERSION"
         fi
     else
         if [ "$IRODS_VERSION" == "4.2.11" ] && [  "$distro" == "ubuntu" ]
         then package_version="4.2.11-1~xenial"
	 elif [ "$IRODS_VERSION" == "4.2.12" ] && [ "$distro" == "ubuntu" ]
	 then package_version="4.2.12-1~bionic"
         elif [ "$IRODS_VERSION" == "4.3.0" ] && [  "$distro" == "ubuntu" ]
         then package_version="4.3.0-1~focal"
         elif [ "$IRODS_VERSION" == "4.3.1" ] && [  "$distro" == "ubuntu" ]
         then package_version="4.3.1-0~focal"
         else # shellcheck disable=SC2034
              package_version="$IRODS_VERSION"
         fi
     fi
}

function write_irods_config()
{

cat > /etc/irods/setup_irods.json << IRODS_CONFIG_END
{
  "admin_password": "$ADMIN_PASSWORD",
  "service_account_environment": {
    "irods_host": "provider.local",
    "irods_port": 1247,
    "irods_user_name": "rods",
    "irods_zone_name": "$ZONE_NAME",
    "irods_client_server_negotiation": "request_server_negotiation",
    "irods_client_server_policy": "CS_NEG_REFUSE",
    "irods_cwd": "/$ZONE_NAME/home/rods",
    "irods_default_hash_scheme": "SHA256",
    "irods_default_resource": "demoResc",
    "irods_encryption_algorithm": "AES-256-CBC",
    "irods_encryption_key_size": 32,
    "irods_encryption_salt_size": 8,
    "irods_encryption_num_hash_rounds": 16,
    "irods_home": "/$ZONE_NAME/home/rods",
    "irods_match_hash_policy": "compatible"
  },
  "host_access_control_config": {
    "access_entries": []
  },
  "hosts_config": {
    "host_entries": []
  },
  "host_system_information": {
    "service_account_user_name": "vagrant",
    "service_account_group_name": "vagrant"
  },
  "server_config": {
    "advanced_settings": {
      "default_log_rotation_in_days": 5,
      "default_number_of_transfer_threads": 4,
      "default_temporary_password_lifetime_in_seconds": 120,
      "maximum_number_of_concurrent_rule_engine_server_processes": 4,
      "maximum_size_for_single_buffer_in_megabytes": 32,
      "maximum_temporary_password_lifetime_in_seconds": 1000,
      "rule_engine_server_execution_time_in_seconds": 120,
      "rule_engine_server_sleep_time_in_seconds": 10,
      "transfer_buffer_size_for_parallel_transfer_in_megabytes": 4,
      "transfer_chunk_size_for_parallel_transfer_in_megabytes": 40
    },
    "catalog_provider_hosts": [
      "provider.local"
    ],
    "catalog_service_role": "provider",
    "default_dir_mode": "0750",
    "default_file_mode": "0600",
    "default_hash_scheme": "SHA256",
    "default_resource_name": "demoResc",
    "environment_variables": {},
    "federation": [],
    "host_resolution": {
            "host_entries": []
    },
    "match_hash_policy": "compatible",
    "negotiation_key": "$NEG_KEY",
    "plugin_configuration": {
      "authentication": {},
      "database": {
        "postgres": {
          "db_host": "localhost",
          "db_name": "ICAT",
          "db_odbc_driver": "PostgreSQL",
          "db_password": "$DB_PASSWORD",
          "db_port": 5432,
          "db_username": "irods"
        }
      },
      "network": {},
      "resource": {},
      "rule_engines": [{
          "instance_name": "irods_rule_engine_plugin-irods_rule_language-instance",
          "plugin_name": "irods_rule_engine_plugin-irods_rule_language",
          "plugin_specific_configuration": {
            "re_data_variable_mapping_set": [
              "core"
            ],
            "re_function_name_mapping_set": [
              "core"
            ],
            "re_rulebase_set": [
              "core"
            ],
            "regexes_for_supported_peps": [
              "ac[^ ]*",
              "msi[^ ]*",
              "[^ ]*pep_[^ ]*_(pre|post)"
            ]
          },
          "shared_memory_instance": "irods_rule_language_rule_engine"
        },
        {
          "instance_name": "irods_rule_engine_plugin-cpp_default_policy-instance",
          "plugin_name": "irods_rule_engine_plugin-cpp_default_policy",
          "plugin_specific_configuration": {}
        }
      ]
    },
    "rule_engine_namespaces": [
      ""
    ],
    "schema_name": "server_config",
    "schema_validation_base_uri": "https://schemas.irods.org/configuration",
    "schema_version": "v3",
    "server_control_plane_encryption_algorithm": "AES-256-CBC",
    "server_control_plane_encryption_num_hash_rounds": 16,
    "server_control_plane_key": "$CP_KEY",
    "server_control_plane_port": 1248,
    "server_control_plane_timeout_milliseconds": 10000,
    "server_port_range_end": 20000,
    "server_port_range_start": 20199,
    "xmsg_port": 1279,
    "zone_auth_scheme": "native",
    "zone_key": "$ZONE_KEY",
    "zone_name": "$ZONE_NAME",
    "zone_port": 1247,
    "zone_user": "rods"
  },
  "default_resource_name": "demoResc"
}
IRODS_CONFIG_END

}
