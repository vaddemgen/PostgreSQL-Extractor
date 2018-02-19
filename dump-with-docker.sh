#!/bin/bash
set -e;

echo '# Loading the environment ...';

CURRENT_PATH=`readlink -f $(dirname $0);`;

# Loading the environment.
export $(cat $CURRENT_PATH/.env | grep -v ^\# | xargs);

if [ ! -f $CURRENT_PATH/.env ]; then
    echo 'Environment file not found!';
    exit;
fi

POSTGRES_VERSION='latest';
REMOTE_CONTAINER_NAME='';
REMOTE_IS_LOCALHOST=false;

function update_env {
    env_path="$CURRENT_PATH/.env";

    cat > "$env_path" <<EOT
# Remote DB
REMOTE_POSTGRES_HOST=$REMOTE_POSTGRES_HOST
REMOTE_POSTGRES_DB=$REMOTE_POSTGRES_DB
REMOTE_POSTGRES_USER=$REMOTE_POSTGRES_USER
REMOTE_POSTGRES_PASSWORD=$REMOTE_POSTGRES_PASSWORD
# Buffer DB
BUFFER_POSTGRES_HOST=$BUFFER_POSTGRES_HOST
BUFFER_POSTGRES_DB=$BUFFER_POSTGRES_DB
BUFFER_POSTGRES_USER=$BUFFER_POSTGRES_USER
BUFFER_POSTGRES_PASSWORD=$BUFFER_POSTGRES_PASSWORD
EOT
}

function create_buffer_db {
    BUFFER_POSTGRES_HOST='127.0.0.1';
    BUFFER_POSTGRES_USER='buffer';
    BUFFER_POSTGRES_DB='buffer';
    BUFFER_POSTGRES_PASSWORD='MzcxNzE2NzJmMmFhMjZmMDJkYzMwMWJlOWM0YzRj';
    docker run -d --rm \
        -e "POSTGRES_DB=$BUFFER_POSTGRES_USER" \
        -e "POSTGRES_USER=$BUFFER_POSTGRES_DB" \
        -e "POSTGRES_PASSWORD=$BUFFER_POSTGRES_PASSWORD" \
        -e "LC_ALL=C.UTF-8" \
        -v $CURRENT_PATH:/dump \
        --name=postgres-buffer \
        -t postgres:$POSTGRES_VERSION > /dev/null;

    export PGPASSWORD=$BUFFER_POSTGRES_PASSWORD;

    # Waiting of the DB.
    set +e
    while : ; do
        # Attempting to connect to the DB
        echo '# Attempting to connect to the DB ...';
        sleep 3;
        result=`docker exec postgres-buffer sh -c "psql -U \\\$POSTGRES_USER \\\$POSTGRES_DB -c \"SELECT version();\" 2> /dev/null"`;
        [[ -z $result ]] || break;
    done
    set -e;

    update_env;
}

function create_network {
    # Creating of networks.
    echo '# Creating of networks ...';

    if [[ -z "$(docker network ls | grep postgres-net)" ]]; then
        docker network create postgres-net > /dev/null;
    fi

    if [[ -z "$(docker network inspect postgres-net | grep $REMOTE_CONTAINER_NAME)" ]]; then
        docker network connect postgres-net $REMOTE_CONTAINER_NAME;
    fi

    docker network connect postgres-net postgres-buffer;

    # Detecting a host of the Buffer DB.
    echo '# Detecting a host of the Buffer DB ...';
    BUFFER_POSTGRES_HOST=`docker network inspect postgres-net | grep -A4 postgres-buffer | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"`;
    echo "postgres-buffer: $BUFFER_POSTGRES_HOST";

    # Detecting a host of the Remote DB (Gateway).
    echo '# Detecting a host of the Remote DB (Gateway) ...';
    REMOTE_POSTGRES_HOST=`docker network inspect postgres-net | grep -A4 $REMOTE_CONTAINER_NAME | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"`;
    echo "$REMOTE_CONTAINER_NAME: $REMOTE_POSTGRES_HOST";

    update_env;
}

function update_localhost_address {
    # Detecting a host of the Buffer DB.
    echo '# Detecting a host of the Buffer DB ...';
    BUFFER_POSTGRES_HOST=`docker inspect postgres-buffer | grep IPAddress | grep -m 1 -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"`;
    echo "Buffer DB: $BUFFER_POSTGRES_HOST";

    # Detecting a host of the Remote DB (Gateway).
    echo '# Detecting a host of the Remote DB (Gateway) ...';
    REMOTE_POSTGRES_HOST=`docker inspect postgres-buffer | grep Gateway | grep -m 1 -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"`;
    echo "Remote DB: $REMOTE_POSTGRES_HOST";

    update_env;
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -d|--container)
    REMOTE_CONTAINER_NAME=$2;
    shift # past argument
    shift # past value
    ;;
    -p|--db-version)
    POSTGRES_VERSION=$2;
    shift # past value
    shift # past argument
    ;;
    -l|--localhost)
    REMOTE_IS_LOCALHOST=true;
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

create_buffer_db;

if [ ! -z $REMOTE_CONTAINER_NAME ]; then
    create_network;
fi

if [[ $REMOTE_IS_LOCALHOST == true ]]; then
    update_localhost_address;
fi

docker exec -t postgres-buffer sh -c 'bash /dump/dump.sh; chmod -R 777 /dump';

# Flushing the buffer container.
echo "# Flushing the buffer container ...";
docker stop postgres-buffer > /dev/null;
