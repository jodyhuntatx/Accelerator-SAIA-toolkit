/*
    Create strong user with CREATEROLE privilege
    Username and password must match those stored in the CyberArk account
    for the strong user.

    This user should NOT be the Master User for the database. Best practice
    is to create a dedicated user with only the required privileges needed
    to create user accounts in the database.
*/
CREATE USER {{TARGET_DB_STRONG_USER}} WITH CREATEROLE;
GRANT {{TARGET_DB_USERROLE}} TO {{TARGET_DB_STRONG_USER}} WITH ADMIN OPTION;
ALTER USER {{TARGET_DB_STRONG_USER}} WITH PASSWORD '{{TARGET_DB_STRONG_PASSWORD}}';
GRANT CONNECT ON DATABASE {{TARGET_DB}} TO {{TARGET_DB_STRONG_USER}};
