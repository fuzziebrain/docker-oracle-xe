# Docker build for Oracle Database 18c Express Edition (XE)

1. Clone this repository.
1. Set the working directory to the project folder.
1. [Download](https://www.oracle.com/technetwork/database/database-technologies/express-edition/downloads/index.html) the RPM from Oracle Technology Network and save it to the `files` subdirectory.
1. Build the image, e.g. `docker build -t odb18c-xe .`
1. Run a container, e.g. `docker run -d --name=oracledb -p 1521:1521 -p 5500:5500 odb18c-xe`