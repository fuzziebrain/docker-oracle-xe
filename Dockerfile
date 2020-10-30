FROM oraclelinux:7-slim
LABEL MAINTAINER="Adrian Png <adrian.png@fuzziebrain.com>"

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
  ORACLE_XE_RPM=oracle-database-xe-18c-1.0-1.x86_64.rpm \
  ORACLE_PRE_RPM=oracle-database-preinstall-18c-1.0-1.el7.x86_64.rpm \
  CHECK_DB_FILE=checkDBStatus.sh

RUN yum install -y wget && \
  cd /tmp && wget --report-speed=bits https://download.oracle.com/otn-pub/otn_software/db-express/${ORACLE_XE_RPM} && \
  curl -o /tmp/oracle-database-preinstall-18c-1.0-1.el7.x86_64.rpm https://yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64/getPackage/${ORACLE_PRE_RPM} && \
  yum install -y /tmp/${ORACLE_PRE_RPM} && \
  yum install -y /tmp/${ORACLE_XE_RPM} && \
  sed -i 's#CHARSET=AL32UTF8##' /etc/sysconfig/oracle-xe-18c.conf && \
  rm -f /tmp/*.rpm

COPY ./scripts/*.sh ${ORACLE_BASE}/scripts/

RUN chmod a+x ${ORACLE_BASE}/scripts/*.sh 

# 1521: Oracle listener
# 5500: Oracle Enterprise Manager (EM) Express listener.
EXPOSE 1521 5500

VOLUME [ "${ORACLE_BASE}/oradata" ]

HEALTHCHECK --interval=1m --start-period=2m --retries=10 \
  CMD "$ORACLE_BASE/scripts/$CHECK_DB_FILE"

CMD exec ${ORACLE_BASE}/scripts/${RUN_FILE}
