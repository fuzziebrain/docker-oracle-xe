FROM oraclelinux:7-slim
LABEL MAINTAINER="Adrian Png <adrian.png@fuzziebrain.com>"

ARG ORACLE_XE_RPM=oracle-database-xe-18c-1.0-1.x86_64.rpm
ARG ORACLE_XE_URL=https://download.oracle.com/otn-pub/otn_software/db-express/${ORACLE_XE_RPM}

ENV \
  # The only environment variable that should be changed!
  ORACLE_PASSWORD=Oracle18 \
  EM_GLOBAL_ACCESS_YN=Y \
  # DO NOT CHANGE 
  ORACLE_DOCKER_INSTALL=true \
  ORACLE_SID=XE \
  ORACLE_BASE=/opt/oracle \
  ORACLE_HOME=/opt/oracle/product/18c/dbhomeXE \
  ORAENV_ASK=NO \
  RUN_FILE=runOracle.sh \
  SHUTDOWN_FILE=shutdownDb.sh \
  EM_REMOTE_ACCESS=enableEmRemoteAccess.sh \
  EM_RESTORE=reconfigureEm.sh \
  CHECK_DB_FILE=checkDBStatus.sh
    
# Download Oracle XE
ADD ${ORACLE_XE_URL} /tmp

RUN echo start && \
  yum install -y oracle-database-preinstall-18c && \
  yum install -y /tmp/${ORACLE_XE_RPM} && \
  rm -rf /tmp/${ORACLE_XE_RPM} && \
  echo end

COPY ./scripts/*.sh ${ORACLE_BASE}/scripts/

RUN chmod a+x ${ORACLE_BASE}/scripts/*.sh 

# 1521: Oracle listener
# 5500: Oracle Enterprise Manager (EM) Express listener.
EXPOSE 1521 5500

VOLUME [ "${ORACLE_BASE}/oradata" ]

HEALTHCHECK --interval=1m --start-period=2m --retries=10 \
  CMD "$ORACLE_BASE/scripts/$CHECK_DB_FILE"

CMD exec ${ORACLE_BASE}/scripts/${RUN_FILE}