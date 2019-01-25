#!/bin/bash
# Original source from: https://github.com/oracle/docker-images/blob/master/OracleDatabase/SingleInstance/dockerfiles/18.3.0/runOracle.sh

# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
# 
# Since: November, 2016
# Author: gerald.venzl@oracle.com
# Description: Runs the Oracle Database inside the container
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

########### Move DB files ############
function moveFiles {

  if [ ! -d $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID ]; then
    mkdir -p $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
  fi;

  # Replace the container's hostname with 0.0.0.0
  sed -i 's/'$(hostname)'/0.0.0.0/g' $ORACLE_HOME/network/admin/listener.ora
  sed -i 's/'$(hostname)'/0.0.0.0/g' $ORACLE_HOME/network/admin/tnsnames.ora

  mv $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
  mv $ORACLE_HOME/dbs/orapw$ORACLE_SID $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
  mv $ORACLE_HOME/network/admin/sqlnet.ora $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
  mv $ORACLE_HOME/network/admin/listener.ora $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
  mv $ORACLE_HOME/network/admin/tnsnames.ora $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/

  # oracle user does not have permissions in /etc, hence cp and not mv
  cp /etc/oratab $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
   
  symLinkFiles;
}

########### Symbolic link DB files ############
function symLinkFiles {

  if [ ! -L $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora ]; then
    ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/spfile$ORACLE_SID.ora $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora
  fi;
   
  if [ ! -L $ORACLE_HOME/dbs/orapw$ORACLE_SID ]; then
    ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/orapw$ORACLE_SID $ORACLE_HOME/dbs/orapw$ORACLE_SID
  fi;
   
  if [ ! -L $ORACLE_HOME/network/admin/sqlnet.ora ]; then
    ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/sqlnet.ora $ORACLE_HOME/network/admin/sqlnet.ora
  fi;

  if [ ! -L $ORACLE_HOME/network/admin/listener.ora ]; then
    ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/listener.ora $ORACLE_HOME/network/admin/listener.ora
  fi;

  if [ ! -L $ORACLE_HOME/network/admin/tnsnames.ora ]; then
    ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/tnsnames.ora $ORACLE_HOME/network/admin/tnsnames.ora
  fi;

  # oracle user does not have permissions in /etc, hence cp and not ln 
  cp $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/oratab /etc/oratab

}

########### SIGINT handler ############
function _int() {
  echo "Stopping container."
  echo "SIGINT received, shutting down database!"
  runuser oracle -s /bin/bash -c "${ORACLE_BASE}/scripts/${SHUTDOWN_FILE} immediate"
}

########### SIGTERM handler ############
function _term() {
  echo "Stopping container."
  echo "SIGTERM received, shutting down database!"
  runuser oracle -s /bin/bash -c "${ORACLE_BASE}/scripts/${SHUTDOWN_FILE} immediate"
}

########### SIGKILL handler ############
function _kill() {
  echo "SIGKILL received, shutting down database!"
  runuser oracle -s /bin/bash -c "${ORACLE_BASE}/scripts/${SHUTDOWN_FILE} abort"
}

###################################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
############# MAIN ################
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
###################################

# Check whether container has enough memory
# Github issue #219: Prevent integer overflow,
# only check if memory digits are less than 11 (single GB range and below) 
if [ `cat /sys/fs/cgroup/memory/memory.limit_in_bytes | wc -c` -lt 11 ]; then
  if [ `cat /sys/fs/cgroup/memory/memory.limit_in_bytes` -lt 2147483648 ]; then
    echo "Error: The container doesn't have enough memory allocated."
    echo "A database container needs at least 2 GB of memory."
    echo "You currently only have $((`cat /sys/fs/cgroup/memory/memory.limit_in_bytes`/1024/1024/1024)) GB allocated to the container."
    exit 1;
  fi;
fi;

# Set SIGINT handler
trap _int SIGINT

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

# Commands
ORACLE_CMD=/etc/init.d/oracle-xe-18c

# Check whether database already exists
if [ -d $ORACLE_BASE/oradata/$ORACLE_SID ]; then
  echo Database exists
   
  # Make sure audit file destination exists
  if [ ! -d $ORACLE_BASE/admin/$ORACLE_SID/adump ]; then
    mkdir -p $ORACLE_BASE/admin/$ORACLE_SID/adump
    chown -R oracle.oinstall $ORACLE_BASE/admin
  fi;
  
  symLinkFiles;
   
  # Start database
  ${ORACLE_CMD} start
  
else
  echo Database does not exists, configuring
 
  mkdir -p ${ORACLE_BASE}/oradata
  chown oracle.oinstall ${ORACLE_BASE}/oradata

  ${ORACLE_CMD} configure

  # Enable EM remote access
  runuser oracle -s /bin/bash -c "${ORACLE_BASE}/scripts/${EM_REMOTE_ACCESS} ${EM_GLOBAL_ACCESS_YN:-N}"

  # Move database operational files to oradata
  moveFiles;
   
fi;

# Check whether database is up and running
# $ORACLE_BASE/scripts/$CHECK_DB_FILE
# if [ $? -eq 0 ]; then
#   echo "#########################"
#   echo "DATABASE IS READY TO USE!"
#   echo "#########################"
  
# else
#   echo "#####################################"
#   echo "########### E R R O R ###############"
#   echo "DATABASE SETUP WAS NOT SUCCESSFUL!"
#   echo "Please check output for further info!"
#   echo "########### E R R O R ###############" 
#   echo "#####################################"
# fi;

# Tail on alert log and wait (otherwise container will exit)
echo "The following output is now a tail of the alert.log:"
tail -f ${ORACLE_BASE}/diag/rdbms/*/*/trace/alert*.log &
childPID=$!
wait ${childPID}

# TODO workaround
tail -f /dev/null
