#!/bin/sh
# Creates one database and one role per service so no service can read another's data.
set -e

create_db() {
  db="$1"; role="$2"; pass="$3"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<SQL
CREATE ROLE ${role} LOGIN PASSWORD '${pass}';
CREATE DATABASE ${db} OWNER ${role};
REVOKE ALL ON DATABASE ${db} FROM PUBLIC;
SQL
}

create_db auth_db     auth_user     "$AUTH_DB_PASSWORD"
create_db calendar_db calendar_user "$CALENDAR_DB_PASSWORD"
create_db finance_db  finance_user  "$FINANCE_DB_PASSWORD"
create_db notes_db    notes_user    "$NOTES_DB_PASSWORD"
