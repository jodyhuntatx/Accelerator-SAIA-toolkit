# Secure Infrastructure Access w/ Zero Standing Privilege

## Workflow Overview
This overview is a preview of the configuration procedure. See detailed procedure section below for step-by-step instructions. They specify free-tier resources for demo purposes. Your objectives may require more substantially provisioned resources. Modify as needed.

0. Edit local.env

In AWS:

1. In RDS, create PostgreSQL DB server
2. In EC2, create EC2 Ubuntu instance for connector

In tenant Administration:

3. Create connector Pool/Network
4. Configure Connector
5. Test connection to DB

In tenant Privilege Cloud:

6. Create accounts for DB admin and strong account

In tenant Secure Infrastructure Access:

7. Download & import RDS CA certificate bundle
8. Onboard DB & Strong account
9. Download full-chain certificate

In tenant Administration:

10. Create Access Policy(s) for users

With shell scripts:

11. Test admin access with vaulted credentials
12. Create database
13. Test ephemeral access

# Detailed Procedure

## 0.  Edit local.env (file in this directory)

Supply missing configuration values in angle brackets. Keep this file open as some of these values are needed during the configuration steps below.

- TENANT_SUBDOMAIN - Your tenant's subdomain ID e.g. if your tenant base URL is
    https://subdomain-id.cyberark.cloud, your subdomain ID is subdomain-id
- CYBR_USERNAME - Your tenant login username.
- CYBR_PASSWORD - Your cached MFA password (see https://<your-subdomain-id>.cyberark.cloud/dpa/adb/short-lived-token>). You will need to update this whenever it expires. It has a defa
- DB_MASTER_USER - The Master user set during DB server creation. This user is for database administration, e.g. creating/updating databases.
- TARGET_DB_STRONG_USER - The strong account username to create in the DB. Must be all lower case and match the username in the strong account in the CyberArk safe.
- TARGET_DB_STRONG_PASSWORD - The strong account password to create in the DB. Must match the password in the strong account in the CyberArk safe.
- TARGET_DB_USERROLE - The limited role to be created for users in the DB. Must be all lower case and match the custom role specified in SIA access policy.
- TARGET_DB_SERVER_FQDN - The fully qualified domain name of the database store. Set this value after the next step.

## 1. Create a PostgreSQL database

- AWS Aurora and RDS
- PostgreSQL, Free tier
- Identifier - name of your choice
- Master username - admin user, best if something other than postgres (the default) to avoid confusion.
- Master password - something you'll remember - record this in local.env if you can't remember it. The master username and password will be saved in an Privilege Cloud account and used for vaulted credential access to the database for administration.
- Opt for defaults for Instance Config, Storage unless you know better.
- Select the same VPC where your EC2 instance will run
- Default for subnet, no public access
- Security group - must allow ingress on 5432, easier if you use same as for EC2
- Availability Zone - no preference
- RDS proxy - none
- CA - default
- Tags - set values for I_Owner & I_Purpose (per CYBR policy)
- Password authn, standard insights, no performance insights
- Create Instance
- Once DB is ready be sure to save connection details (Master uname/pwd, FQDN endpoint) in local.env.

## 2. Create an EC2 instance for your connector

- Name, tags (I_Owner, I_Purpose)
- Ubuntu, default image/arch, size t3.micro, keypair (new/used)
- Edit network settings
- Choose same VPC as DB, enable public IP (IMPORTANT: for SSH)
- Same security group as DB, port 5432 open to security group
- Use defaults for all other values
- Launch Instance
  
## 3. Create connector pool & network

- In the tenant navigate to: Administration->My Environment->Connector Management->Connector Pools
- Click Add Pool
- Enter name for pool, enable Add a network with the pool name
- Save and Continue
- Add target identifier:
  - Identifier type: FQDN
  - Value: FQDN of DB (NOT EC2 instance!!)
  - click Add
- Note: Test will not work because connector is not yet configured.

## 4. Create connector

- In the tenant navigate to: Administration->My Environment->Connector Management->Connectors->SIA Connectors
- Click Add Connector
- Select existing pool just created
- Select Linux
- Don't select proxy server connection
- Select Next, copy script to clipboard
- SSH to your EC2 instance
- Paste copied script at shell prompt in EC2 and run script
- Confirm the connector service is ready:
  - sudo systemctl status cyberark-dpa-connector

## 5. Test connector connection to DB

- In the tenant navigate to: SIA Connectors (as above)
- Click on new connector, click vertical ... in upper right
- Select Test, under Target connection:
  - paste FQDN of DB server (not EC2 instance!), port 5432
- Confirm test success
- Troubleshooting:
  - check DB security group allows ingress on port 5432 from EC2
  - check DB & EC2 are in same VPC
  - make sure both connector pool and connector FQDNs reference the DB (not EC2 instance)

## 6. Create a safe & accounts for the DB admin user and the Strong account

- In the tenant navigate to: Privilege Cloud -> Policies -> Safes
- Click create safe, give meaningful name
- Add member from CyberArk Cloud Directory: "Secure Infrastructure Privilege Cloud Ephemeral Access" role with default Read Only permissions (List/Use/Retrieve Accounts)
- In Privilege Cloud -> Accounts:
  - Create DB Admin Account.\
  This will be used interactively with the psql CLI and vaulted credentials to initialize the DB:
  - Type: Database
  - Platform: Postgres
  - Safe: the one just created w/ ephemeral user role member
  - Username: Master username for DB
  - Password: Master password for DB
  - Address: FQDN for DB
  - Database: do not specify
  - Port: 5432
  - Do NOT enable automated password management.
- Create Strong account.\
  This will be used by SIA to create ephemeral users.
  - Type: Database
  - Platform: Postgres
  - Safe: the one just created w/ ephemeral access role member
  - Username: Strong account username for DB
  - Password: Strong account password for DB
  - Address: FQDN for DB
  - Database: do not specify
  - Port: 5432
  - Do NOT enable automated password management.

## 7. Download and import RDS CA certificate bundle

- In AWS documentation navigate to:\
https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html
- Scroll down to table under "Certificate Bundles by AWS Region"
- Download the certificate by clicking on the correct .pem file for the region in which your DB is running
- In your tenant navigate to: Secure Infrastructure Access->TLS Certificates
- Click: Add a Certificate
- Browse to your downloaded .pem file
- Give the cert a meaningful name, e.g. AWS RDS us-east-2 CA bundle
- Add description & tags as needed
- Click: Add

## 8. Onboard DB and create strong account

- In the tenant navigate to: Secure Infrastructure Access->Resource Management
- Scroll down to Databases, click Onboard a Database.
  - Database: PostgreSQL
  - Location: AWS
  - Service: Amazon RDS PostgreSQL
  - Authentication: Local user
- Database details:
  - Name: postgres
  - Port: 5432
  - R/W address: FQDN of your DB instance
- Strong account details:
  - Select: Create a database's strong account
  - Select: Vaulted in Privilege Cloud
    - Secret name: Can be anything - displayed as tile label
    - Safe: The one you created above w/ ephemeral access role member
    - Account: customized account name for the Strong account in the Safe.
- Enable TLS certificate (required for vaulted credential access)
- Click: "Select a TLS certificate", select the AWS certificate bundle added above.
- Click: "Onboard"

## 9. Download full-chain certificate

- In the tenant navigate to: Secure Infrastructure Access->Connection Guidance
- Click the "Databases" tab.
- Click "Generate and Download" button under "Download full chain certificate", save the file to this directory. If you want to use a different directory and/or file name, modify the PGSSLROOTCERT environment variable in local.env (toward the bottom of the file).

## 10. Create user access policy

- In the tenant navigate to: Administration->Access control policies->User access
- Click: Create Policy -> Database Access
- Name: Best practice is to specify a CyberArk Identity Role (e.g "Secure AI Admins") rather than individual users and a memorable name for the database target.
  - Timeframe, tags as desired
  - Click: Next
- Add database targets, PostgreSQL
- Click: "Add Instance", select target DB for strong account
- Custom roles: enter name of target DB user role in DB server.\
Note this is NOT a CyberArk role, but a database role that will be created when initializing the DB.
- Click: Add, confirm input, click Next
- Click: Add identities, search for users/groups/roles to have access to DB
- Check box(es) for users/groups/roles to add to policy
- Click Add to policy, confirm input, click Next
- Specify desired timeframes for access, click Create policy

## 11. Test DB admin access with vaulted credentials

- In this directory run: ./connect-db.sh VAULTED
- This should connect your user through SIA to the database using the Master user's vaulted credentials.
- If the connection is not successful:
  - ERROR:  DPA_AUTHENTICATION_FAILED: Refresh your cached MFA password in local.env
  - Other errors: Review the steps above and ensure all environment variables in local.env match the values in the Pcloud accounts and SIA configurations.
- DO NOT PROCEED to the next step until this step succeeds.

## 12. Create database using vaulted credentials

- In this directory run: create-petclinic.db.sh
- This will connect as the admin user to initialize the database:
  - Creates the petclinic database (see: db_load_petclinic.sql).
  - Creates the strong user (see: db_create_strong_user.sql)
  - Creates the database role for ephemeral users (see: db_create_userfole.sql)

## 13. Test ephemeral access

- Run: ./connect-db.sh
- Confirm you are connected to the postgres database.
- Run: select * from pets;\
\
Output should be:

```
 id | name  | birth_date | type_id | owner_id \
----+-------+------------+---------+----------\
  1 | Uri   | 2014-01-01 |       1 |        1\
  2 | Lilah | 2013-01-01 |       2 |        2\
  3 | Elsie | 2020-10-25 |       3 |        3\
(3 rows)
```

## 13. Add Claude connector

- 
