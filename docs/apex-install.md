# How to Install APEX in PDB

<!-- TOC -->

- [How to Install APEX in PDB](#how-to-install-apex-in-pdb)
  - [Assumptions](#assumptions)
  - [APEX Installation](#apex-installation)
  - [ORDS](#ords)

<!-- /TOC -->

This documentation will walk through how to create a new PDB and install it. Please ensure that you have [downloaded](https://www.oracle.com/technetwork/developer-tools/apex/downloads/index.html) the latest copy of APEX.

## Assumptions

Item | Description
--- | ---
Container Name | Container name is `oracle-xe`
APEX Version | `18.2`. The zip file is located in: 
PDB | `XEPDB1` (_default PDB that comes with XE_)
APEX Admin Password: `Oradoc_db1`


## APEX Installation

```bash
# Copy APEX zip file to container
docker cp ~/docker/files/apex/apex_18.2_en.zip oracle-xe:/tmp

# Login to container
docker exec -it oracle-xe bash -c "source /home/oracle/.bashrc; bash"

# Next set of commands are in the container
cd /tmp/
unzip apex_18.2_en.zip
cd apex

# Download APEX install file
curl https://raw.githubusercontent.com/fuzziebrain/docker-oracle-xe/master/files/apex-install.sql --output apex-install.sql

# Connect to PDB and install APEX
$ORACLE_HOME/bin/sqlplus sys/Oracle18@localhost/XEPDB1 as sysdba @apex-install.sql Oradoc_db1

# Delete APEX files 
cd /tmp
rm -rf apex*

exit
```

## ORDS

[docker-ords](https://github.com/martindsouza/docker-ords) contains instructions on how to setup a docker instance of ORDS
