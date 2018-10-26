#!/bin/bash

. oraenv 

$ORACLE_HOME/bin/sqlplus / as sysdba <<EOF
  shutdown $1;
  exit;
EOF

$ORACLE_HOME/bin/lsnrctl stop
