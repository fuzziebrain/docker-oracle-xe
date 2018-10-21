#!/bin/bash

export ORACLE_SID=XE
export ORAENV_ASK=NO
. /opt/oracle/product/18c/dbhomeXE/bin/oraenv

sqlplus / as sysdba << EOF
  exec dbms_xdb.setlistenerlocalaccess(false);
EOF