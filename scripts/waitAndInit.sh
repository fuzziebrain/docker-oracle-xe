#!/bin/bash
dir=$(dirname $0)

STATUS=-1
while [[ $STATUS -ne 0 ]]; do
  sleep 4
  echo Checking Oracle status...
  $dir/checkDBStatus.sh
  STATUS=$?
done

echo "Looking for init files in '/docker-entrypoint-initdb.d':"

for f in $(ls /docker-entrypoint-initdb.d/*); do
  echo "found file $f"
  case "$f" in
  *.sh)
    echo "[IMPORT] $0: running $f"
    . "$f"
    ;;
  *.sql)
    echo "[IMPORT] $0: running $f"
    echo "exit" | su oracle -c "$ORACLE_HOME/bin/sqlplus -S / as sysdba @$f"
    echo
    ;;
  *) echo "[IMPORT] $0: ignoring $f" ;;
  esac
  echo
done

if [[ -n "$ORACLE_USER" && -n "$ORACLE_PASSWORD" ]]; then
  echo "Initializing database $ORACLE_DB from environment variables"
  su oracle -c "$ORACLE_HOME/bin/sqlplus -S / as sysdba" <<-EOF
    alter session set "_ORACLE_SCRIPT"=true;
    Create user $ORACLE_USER identified by $ORACLE_PASSWORD;
    GRANT create session TO $ORACLE_USER;
    GRANT create table TO $ORACLE_USER;
    GRANT create view TO $ORACLE_USER;
    GRANT create any trigger TO $ORACLE_USER;
    GRANT create any procedure TO $ORACLE_USER;
    GRANT create sequence TO $ORACLE_USER;
    GRANT create synonym TO $ORACLE_USER;
    GRANT UNLIMITED TABLESPACE TO $ORACLE_USER;
EOF

fi
