#!/bin/bash

if [[ $# > 0 ]]; then
  CONNECT_MODE="VAULTED"
fi

set -a
source ./local.env

echo
echo "psql commands:"
echo "  \l - list all databases"
echo "  \c <database> - connect to a specific database"
echo "  \d - list all tables in the current database"
echo "  \d <table> - describe a specific table"
echo "  \q - quit the psql command line"
echo "  \h - help for psql commands"
echo; echo

set -x
psql  "host=$SIA_DB_ENDPOINT        \
      user=$SIA_CONNECTION_STRING   \
      dbname=$TARGET_DB             \
      password=$CYBR_PASSWORD"
