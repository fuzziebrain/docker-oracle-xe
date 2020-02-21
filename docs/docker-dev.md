# Docker Development for Oracle XE

- [Build Image](#build-image)
  - [Using VSCode](#using-vscode)
  - [Manually](#manually)
- [Scripts](#scripts)
  - [Run container and destroy:](#run-container-and-destroy)
- [Documentation](#documentation)

This document is for developers managing and contributing to this project.

## Build Image

### Using VSCode
If using [VSCode](https://code.visualstudio.com/) just run task (`Task: Run Build Task`) and select `build: docker-oracle-xe`.

### Manually

```bash
-- Clone repo
git clone git@github.com:fuzziebrain/docker-oracle-xe.git

-- Build Image
docker build -t oracle-xe:18c .
```

## Scripts

### Run container and destroy:

```bash
docker run -it --rm \
  -p 32118:1521 \
  --network=oracle_network \
  --volume ~/docker/oracle-xe:/opt/oracle/oradata \
  oracle-xe:18c
```


## Documentation

The TOC on the main [README.md](README.md) uses [Markdown TOC](https://marketplace.visualstudio.com/items?itemName=AlanWalk.markdown-toc) for VS Code.