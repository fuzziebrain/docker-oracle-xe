#!/bin/bash

# Commands
ORACLE_CMD=/etc/init.d/oracle-xe-18c
if [ -z "$GREP" ]; then GREP=/usr/bin/grep; fi
if [ ! -f "$GREP" ]; then GREP=/bin/grep; fi
if [ -z "$TAIL" ]; then TAIL=/usr/bin/tail; fi
if [ ! -f "$TAIL" ]; then TAIL=/bin/tail; fi

function _stop() {
   ${ORACLE_CMD} stop
}

trap _stop SIGINT

trap _stop SIGTERM

trap _stop SIGKILL

# Starting up!
configfile=`$GREP --no-messages $ORACLE_SID:$ORACLE_HOME /etc/oratab` > /dev/null 2>&1

if [ "$configfile" = "" ]
then
  ${ORACLE_CMD} configure

  # Enable EM remote access
  runuser oracle -s /bin/bash -c ${ORACLE_BASE}/scripts/${EM_REMOTE_ACCESS}
else
  ${ORACLE_CMD} start
fi

# Tail on alert log and wait (otherwise container will exit)
echo "The following output is now a tail of the alert.log:"
tail -f ${ORACLE_BASE}/diag/rdbms/*/*/trace/alert*.log &
childPID=$!
wait ${childPID}