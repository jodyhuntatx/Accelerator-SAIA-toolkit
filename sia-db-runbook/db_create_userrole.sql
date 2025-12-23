/*
  Create user role with read-only access to database.
  The is a role to specify in a SIA ZSP access policy.
  SIA will login as the Strong User to create ephemeral users with this role.
*/
CREATE ROLE {{TARGET_DB_USERROLE}};
-- Read-only access for database
GRANT CONNECT ON DATABASE {{TARGET_DB}} TO {{TARGET_DB_USERROLE}};
-- Read-only access for all existing tables in public schema
GRANT SELECT ON ALL TABLES IN SCHEMA public TO {{TARGET_DB_USERROLE}};
-- Read-only access for all future tables in public schema
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO {{TARGET_DB_USERROLE}};