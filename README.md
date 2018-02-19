# Extracts a PostgreSQL database into a script file with fake user data.

## Overview

The documentation describes how to use the scripts `dump-with-docker.sh` and `docker.sh`.

The scripts need a Postgres DB for buffering (**Buffer**). Make sure that the remote PostgreSQL (**Remote**) has the same version with the **Buffer**.

## How it works

First, the script extracts a remote PostgreSQL database (**Remote**) into a dump file with a format **.sql**. Secondly, the dump is restored to the **Buffer**. Then the commands written in the file `script.sql` are processed in the **Buffer**. Finally, the script make a dump and compresses it into the `gzip` archive.

## _dump-with-docker.sh_ vs _docker.sh_

You can use `dump-with-docker.sh` or `docker.sh` scripts. Both scripts create a DB dump, but there is a difference.

If you use `docker.sh`, you should provide access to the **Buffer DB** and **Remote DB** in `.env`. These options are discussed below (See the paragraph **_II. Dump with docker.sh_**).

Unlike this script, the `dump-with-docker.sh` automatically creates a container for the Buffer DB, but you need to provide access to the **Remote DB** in `.env`. These options are discussed below (See the paragraph **_I. Make a dump using `dump-with-docker.sh`_**).

## I. Make a dump using `dump-with-docker.sh`

The script will create a docker container and clean up it after.

### Options

 Name, shorthand   |     Value      | Default  |                           Description
:----------------: | :------------: | :------: | :-------------------------------------------------------------:
`-d, --container`  | container_name |   none   | The Remote is local docker container with name `container_name`
`-p, --db-version` |   pg_version   | `latest` |              A version of Buffer (PostgresSQL DB).
`-l, --localhost`  |       -        |    -     |               Says that the Remote is localhost.

### Environment

Please provide environment variables in `.env` before.

Access to the Remote:

- `REMOTE_POSTGRES_HOST` - Specifies the host name of the machine on which the server is running.
- `REMOTE_POSTGRES_DB` - Specifies the name of the database to connect to.
- `REMOTE_POSTGRES_USER` - Connect to the database as the user instead of the default.
- `REMOTE_POSTGRES_PASSWORD` - The password connection parameter.

### Usage

- **Dumping Remote**

  ```
  bash dump-with-docker.sh
  ```

  Or:

  ```
  bash dump-with-docker.sh -p 9.6.2
  ```

  Where `9.6.2` is the version of remote PostgreSQL.

- **Dumping a local docker container**

  ```
  bash dump-with-docker.sh -d container_name
  ```

  Where `container_name` is the name of local container.

  Or:

  ```
  bash dump-with-docker.sh -d container_name -p 9.6.2
  ```

  Where `9.6.2` is the version of remote PostgreSQL.

- **Dumping a localhost**

  Make sure that the local PostgreSQL allows remote connections.

  Example of configuration for the PostgreSQL for your local machine:

    - Change the current directory:

      ```
      cd /etc/postgresql/9.x/main/
      ```

    - Open file named `postgresql.conf`:

      ```
      sudo vi postgresql.conf
      ```

    - Add this line to that file:

      ```
      listen_addresses = '*'
      ```

    - Then open file named `pg_hba.conf`:

      ```
      sudo vi pg_hba.conf
      ```

    - And add this line to that file:

      ```
      host  all  all 0.0.0.0/0 md5
      ```

    - It allows access to all databases for all users with an encrypted password. Restart your server.

      ```
      sudo /etc/init.d/postgresql restart
      ```

  Execute a script:

  ```
  bash dump-with-docker.sh -l
  ```

  Or:

  ```
  bash dump-with-docker.sh -l -p 9.6.2
  ```

  Where `9.6.2` is the version of remote PostgreSQL.

## II. Dump with `docker.sh`

### Environment

Please provide environment variables in `.env` before.

- Access to the Remote:

  - `REMOTE_POSTGRES_HOST` - Specifies the host name of the machine on which the server is running.
  - `REMOTE_POSTGRES_DB` - Specifies the name of the database to connect to.
  - `REMOTE_POSTGRES_USER` - Connect to the database as the user instead of the default.
  - `REMOTE_POSTGRES_PASSWORD` - The password connection parameter.

- Buffer DB:

  - `BUFFER_POSTGRES_HOST` - Specifies the host name of the machine on which the server is running.
  - `BUFFER_POSTGRES_DB` - Specifies the name of the database to connect to.
  - `BUFFER_POSTGRES_USER` - Connect to the database as the user instead of the default.
  - `BUFFER_POSTGRES_PASSWORD` - The password connection parameter.

## How to use?

1. Create an Environment Configuration File.

  ```
  cp schoolupdate-dump/.env.example schoolupdate-dump/.env
  ```

2. Provide access to **Remote DB** and **Buffer** in the `.env`.

3. Execute the script:

  ```
  bash dump.sh
  ```

4. In the script directory you can find the dump.

## How to dockerize **Buffer**?

### Overview

If you need a specific version of **Buffer**, you can use Docker. Creating a **Buffer** consists of the following steps:

- Create a Docker container.
- Link the container with the remote PostgreSQL.
- Connect to the container.
- Execute the script.

### 1\. Creating a docker container for the Buffer.

Please find a full path to the script directory:

```
readlink -f $(dirname dump.sh)
```

Replace the following parameters before running the next command:

- `/path/to/dump_dir` - a full path to the script directory.
- `postgres:latest` - a version of PostgreSQL, e.g. `postgres:10`, `postgres:9.6.7`.

```sh
docker run --rm \
    -e "POSTGRES_DB=buffer" \
    -e "POSTGRES_USER=buffer" \
    -e "POSTGRES_PASSWORD=MzcxNzE2NzJmMmFhMjZmMDJkYzMwMWJlOWM0YzRj" \
    -e "LC_ALL=C.UTF-8" \
    -v /path/to/dump_dir:/dump \
    --name=postgres-buffer \
    -t postgres:latest
```

> Note: The container will be cleaned up after it stops.

### 2\. Linking the container with the remote PostgreSQL

If **Remote DB** is a Docker container, please follow this step.

Please do the following:

- Create a _Bridge_:

  ```
    docker network create postgres-net
  ```

- Connect **Remote DB** and **Buffer** to this network:

  ```
    docker network connect postgres-net postgres-buffer
    docker network connect postgres-net schoolupdate-postgres
  ```

- Check IP addresses of the containers:

  ```
    docker network inspect postgres-net
  ```

- Put this IPs to the `.env`.

### 3\. Executing of the script

- Connect to the Buffer's container:

  ```
    docker exec -u root -it postgres-buffer bash
  ```

  The script directory mounted by path `/dump`;

- Execute the script:

  ```
    bash /dump/dump.sh
  ```

- Disconnect from the container.

  The dump is created in the script directory.
