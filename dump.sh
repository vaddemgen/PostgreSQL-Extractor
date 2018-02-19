#!/bin/bash
set -e;

CURRENT_PATH=`readlink -f $(dirname $0);`;

# Loading the environment.
export $(cat $CURRENT_PATH/.env | grep -v ^\# | xargs);

if [ ! -f $CURRENT_PATH/.env ]; then
    echo 'Environment file not found!';
    exit;
fi

# Readling DB version.
echo '# Readling DB version ...';
export PGPASSWORD=$REMOTE_POSTGRES_PASSWORD;
remote_version=`psql -h $REMOTE_POSTGRES_HOST -U $REMOTE_POSTGRES_USER $REMOTE_POSTGRES_DB -c "SELECT version();" | sed -n 3p`;
echo "Remote DB:$remote_version";
export PGPASSWORD=$BUFFER_POSTGRES_PASSWORD;
buffer_version=`psql -h $BUFFER_POSTGRES_HOST -U $BUFFER_POSTGRES_USER $BUFFER_POSTGRES_DB -c "SELECT version();" | sed -n 3p`;
echo "Buffer DB:$buffer_version";

# Taking the Postgres dump of Confluence database
echo '# Taking the Postgres dump of Confluence database ...';
export PGPASSWORD=$REMOTE_POSTGRES_PASSWORD;
pg_dump -O -x -h $REMOTE_POSTGRES_HOST -U $REMOTE_POSTGRES_USER $REMOTE_POSTGRES_DB > $CURRENT_PATH/tmp.sql;

# Creating a Buffer DB.
echo '# Creating a Buffer DB ...';
export PGPASSWORD=$BUFFER_POSTGRES_PASSWORD;
if psql -h $BUFFER_POSTGRES_HOST -U $BUFFER_POSTGRES_USER -lqt | cut -d \| -f 1 | grep -qw $BUFFER_POSTGRES_DB; then
    dropdb -h $BUFFER_POSTGRES_HOST -U $BUFFER_POSTGRES_USER $BUFFER_POSTGRES_DB;
fi
createdb -h $BUFFER_POSTGRES_HOST -U $BUFFER_POSTGRES_USER $BUFFER_POSTGRES_DB;

# Locading the DB dump into the Buffer DB.
echo '# Locading the DB dump into the Buffer DB ...';
psql -h $BUFFER_POSTGRES_HOST -U $BUFFER_POSTGRES_USER $BUFFER_POSTGRES_DB < $CURRENT_PATH/tmp.sql > /dev/null;

# Updating secret fields.
echo '# Updating secret fields ...';
psql -h $BUFFER_POSTGRES_HOST -U $BUFFER_POSTGRES_USER $BUFFER_POSTGRES_DB -f $CURRENT_PATH/script.sql > /dev/null;

# Making a dump.
echo '# Making a dump ...';
export GZIP=-9;
file_name="$CURRENT_PATH/dump-schoolupdate-$(date '+%Y-%m-%d_%H-%M-%S').sql.gz";
pg_dump -O -x -h $BUFFER_POSTGRES_HOST -U $BUFFER_POSTGRES_USER $BUFFER_POSTGRES_DB | gzip > $file_name;
rm $CURRENT_PATH/tmp.sql;

echo "Done! The file: $file_name";
