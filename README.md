# Docker build for Oracle Database 18c Express Edition (XE)

<!-- TOC depthFrom:2 -->

- [Prerequisites](#prerequisites)
- [Build Image](#build-image)
- [Run Container](#run-container)
- [Container Commands](#container-commands)
- [Other](#other)
  - [SQL](#sql)
  - [APEX Install](#apex-install)
  - [SSH into Container](#ssh-into-container)
  - [OEM](#oem)
  - [Creating a PDB](#creating-a-pdb)
  - [`emp` and `dept` tables](#emp-and-dept-tables)
  - [Preserving `/opt/oracle/oradata` for Multiple Copies](#preserving-optoracleoradata-for-multiple-copies)
- [Docker Developers](#docker-developers)

<!-- /TOC -->

## Prerequisites

1. [Download](https://www.oracle.com/technetwork/database/database-technologies/express-edition/downloads/index.html) the RPM from Oracle Technology Network and save to folder. We will assume it is in `~/Downloads/oracle-database-xe-18c-1.0-1.x86_64.rpm`.

1. _Optional:_ Setup docker network: `docker network create oracle_network`. This is useful if you want other containers to connect to your database (ORDS for example). You can change `oracle_network` for any name you want, however this name will be used in all the code snippets below. 

1. _Optional:_ Create a folder `mkdir ~/docker/oracle-xe` which will store your Oracle XE data to be preserved after the container is destroyed.

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

## Other

### SQL

_Note `sqlcl` is an alias for [SQLcl](https://www.oracle.com/database/technologies/appdev/sqlcl.html). Can also use `sqlplus`_

```bash
-- Connect to CDB
sqlcl sys/Oracle18@localhost:32118/XE as sysdba


-- Connect to default PDB
sqlcl sys/Oracle18@localhost:32118/XEPDB1 as sysdba
```

### APEX Install

An example to install APEX into the default container is available [here](docs/apex-install.md).

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

### Creating a PDB

First connect to the CDB as `sysdba`: `sqlcl sys/Oracle18@localhost:32118/XE as sysdba`

```sql
-- Note XEPDB1 is created by default so demoing with XEPDB2
create pluggable database xepdb2 admin user pdb_adm identified by Oradoc_db1
  file_name_convert=('/opt/oracle/oradata/XE/pdbseed','/opt/oracle/oradata/XE/XEPDB2');

-- Running the following query will show the newly created PDBs but they are not open for Read Write:
select vp.name, vp.open_mode
from v$pdbs vp;

-- Open the PDB
alter pluggable database xepdb2 open read write;

-- If nothing is changed the PDBs won't be loaded on boot.
-- They're a few ways to do this
-- See for reference https://asktom.oracle.com/pls/asktom/f?p=100:11:0::::P11_QUESTION_ID:9531671900346425939
-- alter pluggable database pdb_name save state;
-- alter pluggable database all save state;
-- alter pluggable database all except pdb$seed open read write
alter pluggable database all save state;
```

To connect to the new PDB :

```bash
# Note: the password is the CDB SYS password, not the pdb_adm admin user
sqlcl sys/Oracle18@localhost:32118/XEPDB2 as sysdba
```

### `emp` and `dept` tables

Install `emp` and `dept` sample tables:</br>

`@https://raw.githubusercontent.com/OraOpenSource/OXAR/master/oracle/emp_dept.sql`


### Preserving `/opt/oracle/oradata` for Multiple Copies

Each time you start a container that does has an empty `/opt/oracle/oradata` Oracle XE is configured and the data files are created for the CDB and one PDB (`XEPDB1`). If you plan to launch multiple separate containers for Oracle XE, it is unnecessary to spend this time waiting for the same base files to be created. The solution is fairly simple. It involves creating a sample/seed container, extracting the data files, then copying those data files each time you launch a new container for a new instance of Oracle XE. The following commands demonstrates how to do this:

```bash
docker run -d \
  --name=oracle-xe-seed \
  oracle-xe:18c

# Monitor the status:
docker logs oracle-xe-seed

# Once the Database is fully configured (you'll see a message like:)
# "The following output is now a tail of the alert.log:"
# Running docker ps oracle-xe-seed should also show status "(healthy)'
# Copy the oradata files tso a location (ex: ~/docker/oracle-xe)
# Note you'll probably want to store this in a shared NAS etc
docker cp oracle-xe-seed:/opt/oracle/oradata ~/docker/oracle-xe-seed

# You no longer need the container so stop and remove it
docker stop oracle-xe-seed
docker rm oracle-xe-seed
```

Each time you create a new instance of XE, copy the base `oradata` files and mount them as volume. The following examples shows how to create two copies of Oracle XE:

```bash
# Copy the data files for 01 and 02
cp  ~/docker/oracle-xe-seed ~/docker/oracle-xe01
cp  ~/docker/oracle-xe-seed ~/docker/oracle-xe02

# Start new containers
docker run -d \
  --name=oracle-xe01 \
  -p 32181:1521 \
  --network=oracle_network \
  --volume ~/docker/oracle-xe01:/opt/oracle/oradata \
  oracle-xe:18c

docker run -d \
  --name=oracle-xe02 \
  -p 32182:1521 \
  --network=oracle_network \
  --volume ~/docker/oracle-xe02:/opt/oracle/oradata \
  oracle-xe:18c

# You should see both containers running now:
docker ps

CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                            PORTS                               NAMES
69b52a37a1c6        oracle-xe:18c       "/bin/sh -c 'exec ${…"   8 minutes ago       Up 8 minutes (health: starting)   5500/tcp, 0.0.0.0:32182->1521/tcp   oracle-xe02
14eea4c699d3        oracle-xe:18c       "/bin/sh -c 'exec ${…"   9 minutes ago       Up 9 minutes (health: starting)   5500/tcp, 0.0.0.0:32181->1521/tcp   oracle-xe01
```

## Docker Developers

If you're interested in helping maintain this project check out [docker-dev](docs/docker-dev.md) document.
