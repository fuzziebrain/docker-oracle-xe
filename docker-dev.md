# Docker Development for Oracle XE

This document is for developers managing and contributing to this project.

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