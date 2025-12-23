#!/bin/bash

# Use vaulted Master user credentials to initialize DB
CONNECT_MODE="VAULTED"

set -a
source ./local.env

if [[ "$ALL_GOOD" == "false" ]]; then
  exit 1
fi

: <<EOF
  Databases contain a default schema named "public" that is created automatically when a
  database is created. Schemas contain tables, views, and other database objects.

  This script creates the database, loads the initial data, and creates a
  strong user and user role with read-only access to the database.
EOF

PGPASSWORD=$CYBR_PASSWORD
echo "Creating $TARGET_DB database..."
echo "create database $TARGET_DB;"        \
  | psql  "host=$SIA_DB_ENDPOINT          \
          user=$SIA_CONNECTION_STRING"

echo "Loading $TARGET_DB database schema and data..."
cat db_load_petclinic.sql                 \
  | psql  "host=$SIA_DB_ENDPOINT          \
          user=$SIA_CONNECTION_STRING     \
          dbname=$TARGET_DB"

echo "Creating strong user account $TARGET_DB_STRONG_USER in $TARGET_DB database..."
cat db_create_strong_user.sql             \
  | sed -e "s/{{TARGET_DB_STRONG_USER}}/$TARGET_DB_STRONG_USER/g"         \
        -e "s/{{TARGET_DB_STRONG_PASSWORD}}/$TARGET_DB_STRONG_PASSWORD/g" \
        -e "s/{{TARGET_DB_USERROLE}}/$TARGET_DB_USERROLE/g"               \
        -e "s/{{TARGET_DB}}/$TARGET_DB/g" \
  | psql  "host=$SIA_DB_ENDPOINT          \
          user=$SIA_CONNECTION_STRING     \
          dbname=$TARGET_DB"

echo "Creating user role $TARGET_DB_USERROLE in $TARGET_DB database..."
cat db_create_userrole.sql                \
  | sed -e "s/{{TARGET_DB_USERROLE}}/$TARGET_DB_USERROLE/g" \
        -e "s/{{TARGET_DB}}/$TARGET_DB/g"                   \
  | psql  "host=$SIA_DB_ENDPOINT          \
          user=$SIA_CONNECTION_STRING     \
          dbname=$TARGET_DB"

