#!/usr/bin/env bash
set -e
export PGPASSWORD=$POSTGRES_PASSWORD;
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  CREATE DATABASE $APP_DB_NAME;
  CREATE USER $APP_DB_USER WITH PASSWORD '$APP_DB_PASS';
  GRANT ALL PRIVILEGES ON DATABASE $APP_DB_NAME TO $APP_DB_USER;
  GRANT USAGE ON SCHEMA public TO $APP_DB_USER;
  ALTER DATABASE $APP_DB_NAME OWNER TO $APP_DB_USER;
  \connect $APP_DB_NAME $APP_DB_USER
  BEGIN;
    CREATE TABLE IF NOT EXISTS resources (
      id_resource serial primary key, 
      url text not null, 
      date_upd timestamp without time zone DEFAULT now(), 
      http_status smallint, 
      headers_field jsonb, valid bool default true
    );
    INSERT INTO resources ( url ) VALUES ( 'google.com' ), ( 'http://insane_incorrect_url.com' );
  COMMIT;
EOSQL