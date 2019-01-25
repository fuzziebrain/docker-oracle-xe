#!/bin/bash

. oraenv 

GLOBAL_ACCESS=${1:-N}

if [ $GLOBAL_ACCESS = "Y" ]; then 
  GLOBAL_ACCESS="true"
else
  GLOBAL_ACCESS="false"
fi;

echo "Enabling XDB for external access"
sqlplus / as sysdba << EOF
  exec dbms_xdb_config.setlistenerlocalaccess(false);
  exec dbms_xdb_config.setglobalportenabled($GLOBAL_ACCESS);
EOF