-- Create additional databases and users for microservices
-- This script runs under the default POSTGRES_USER (token_service)

-- Auth Service
CREATE USER auth_service WITH PASSWORD 'auth_secret_dev';
CREATE DATABASE auth_db OWNER auth_service;

-- Grant auth_service full privileges on its database
GRANT ALL PRIVILEGES ON DATABASE auth_db TO auth_service;
\c auth_db
GRANT USAGE, CREATE ON SCHEMA public TO auth_service;
