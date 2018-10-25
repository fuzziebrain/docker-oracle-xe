# Docker build for Oracle Database 18c Express Edition (XE)

## Prerequisites

1. [Download](https://www.oracle.com/technetwork/database/database-technologies/express-edition/downloads/index.html) the RPM from Oracle Technology Network and save to folder. 

1. _Optional:_ Setup docker network: `docker network create oracle_network`. This is useful if you want other containers to connect to your database (ORDS for example) 

## Build Image

```bash
-- Clone repo
git clone git@github.com:fuzziebrain/docker-oracle-xe.git

-- Set the working directory to the project folder
cd docker-oracle-xe

-- Copy the RPM to docker-odb18c-xe/files
cp ~/Downloads/oracle-database-xe-18c-1.0-1.x86_64.rpm files/

-- Build Image
docker build -t oracle-xe:18c .
```

## Run Container

_Note it will take a while on first run for the `oracle-xe configure` to complete_

`/tmp/apex` is an optional mapping to install APEX
__
```bash
docker run -d \
  --name=oracle-xe \
  -p 32118:1521 \
  -p 35518:5500 \
  --volume ~/docker/oracle-xe:/opt/oracle/oradata \
  oracle-xe:18c
  
-- As this takes a long time to run you can keep track of the initial installation by running:
docker logs oracle-xe
```


Alternate option to preserve Oracle Data

```bash
# docker run -it --rm \

docker run -d \
  --name=oracle-xe \
  oracle-xe:18c

docker stop oracle-xe

docker cp oracle-xe:/opt/oracle/oradata ~/docker/oracle-xe
docker cp oracle-xe:/opt/oracle/product/18c/dbhomeXE/network/admin/ ~/docker/oracle-xe

docker rm oracle-xe

# New container
docker run -d \
  --name=oracle-xe \
  -p 32118:1521 \
  -p 35518:5500 \
  --network=oracle_network \
  --volume ~/docker/oracle-xe/oradata:/opt/oracle/oradata \
  --volume ~/docker/oracle-xe/admin:/opt/oracle/product/18c/dbhomeXE/network/admin/ \
  --volume ~/docker/apex:/tmp/apex \
  oracle-xe:18c

# New from Gerald
docker run -d \
  --name=oracle-xe \

docker run -it --rm \
  -p 32118:1521 \
  -p 35518:5500 \
  --network=oracle_network \
  --volume ~/docker/oracle-xe:/opt/oracle/oradata \
  oracle-xe:18c

```

To start and stop the container:

```bash
docker start oracle-xe

docker stop oracle-xe
```

## Connecting

### SQL

```bash
-- Connect to CDB
sqlcl sys/Oracle18@localhost:32118/XE as sysdba


-- Connect to default PDB
sqlcl sys/Oracle18@localhost:32118/XEPDB1 as sysdba

```

### Bash

In some cases you may need to login to the server to modify or test something on the file system.

```bash
docker exec -it oracle-xe bash -c "source /home/oracle/.bashrc; bash"

# Once connected to run sqlplus:
$ORACLE_HOME/bin/sqlplus sys/Oracle18@localhost/XE as sysdba
$ORACLE_HOME/bin/sqlplus sys/Oracle18@localhost/XEPDB1 as sysdba


# Listener start/stop
$ORACLE_HOME/bin/lsnrctl stop
$ORACLE_HOME/bin/lsnrctl start
```

### OEM

_Note: Flash is required_</br>

https://localhost:35518/em


## Other

Install `emp` and `dept` sample tables:</br>

`@https://raw.githubusercontent.com/OraOpenSource/OXAR/master/oracle/emp_dept.sql`