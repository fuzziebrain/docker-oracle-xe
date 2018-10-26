#!/bin/bash

. oraenv 

echo "Enabling XDB for external access"
sqlplus / as sysdba << EOF
  exec dbms_xdb_config.setlistenerlocalaccess(false);
EOF