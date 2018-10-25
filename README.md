# Docker build for Oracle Database 18c Express Edition (XE)

<!-- TOC depthFrom:2 -->

- [Prerequisites](#prerequisites)
- [Build Image](#build-image)
- [Run Container](#run-container)
- [Container Commands](#container-commands)
- [Connecting](#connecting)
  - [SQL](#sql)
  - [SSH into Container](#ssh-into-container)
  - [OEM](#oem)
- [Other](#other)
- [Docker Developers](#docker-developers)
- [Alternate option to preserve Oracle Data (TODO)](#alternate-option-to-preserve-oracle-data-todo)

<!-- /TOC -->

## Prerequisites

1. [Download](https://www.oracle.com/technetwork/database/database-technologies/express-edition/downloads/index.html) the RPM from Oracle Technology Network and save to folder. We will assume it is in `~/Downloads/oracle-database-xe-18c-1.0-1.x86_64.rpm`.

1. _Optional:_ Setup docker network: `docker network create oracle_network`. This is useful if you want other containers to connect to your database (ORDS for example). You can change `oracle_network` for any name you want, however this name will be used in all the code snippets below. 

1. _Optional:_ Create a folder called `mkdir ~/docker/oracle-xe` which will store your Oracle XE data to be preserved after the container is destroyed.

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

_Note first time will take a a while to run for as the `oracle-xe configure` script needs to complete_

```bash
docker run -d \
  -p 32118:1521 \
  -p 35518:5500 \
  --name=oracle-xe \
  --volume ~/docker/oracle-xe:/opt/oracle/oradata \
  --network=oracle_network \
  oracle-xe:18c
  
# As this takes a long time to run you can keep track of the initial installation by running:
docker logs oracle-xe
```

Run parameters:

Name | Required | Description 
--- | --- | ---
`-p 1521`| Required | TNS Listener. `32118:1521` maps `32118` on your laptop to `1521` on the container.
`-p 5500`| Optional | Enterprise Manager (EM) Express. `35518:5500` maps `35518` to your laptop to `5500` on the container. You can then access EM via https://localhost:35518/em 
`--name` | Optional | Name of container. Optional but recommended
`--volume /opt/oracle/oradata` | Optional | (recommended) If provided, data files will be stored here. If the container is destroyed can easily rebuild container using the data files.
`--network` | Optional | If other containers need to connect to this one (ex: [ORDS](https://github.com/martindsouza/docker-ords)) then they should all be on the same docker network.
`oracle-xe:18c` | Required | This is the `name:tag` of the docker image that was built in the previous step

## Container Commands

```bash
# Status:
# Look under the STATUS column for "(health: ...".
docker ps

# Start container
docker start oracle-xe

# Stop container
docker stop -t 200 oracle-xe
```

## Connecting

### SQL

_Note `sqlcl` is an alias for [SQLcl](https://www.oracle.com/database/technologies/appdev/sqlcl.html). Can also use `sqlplus`_

```bash
-- Connect to CDB
sqlcl sys/Oracle18@localhost:32118/XE as sysdba


-- Connect to default PDB
sqlcl sys/Oracle18@localhost:32118/XEPDB1 as sysdba

```

### SSH into Container

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

## Docker Developers

If you're interested in helping maintain this project check out [docker-dev](docker-dev.md) document.


## Alternate option to preserve Oracle Data (TODO)

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