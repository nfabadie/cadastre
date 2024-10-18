-- Create the database named "cadastre"
CREATE DATABASE cadastre;

-- Connect to the "cadastre" database
\c cadastre

-- Enable the PostGIS extension
CREATE EXTENSION postgis;

-- Create the schema named "travail"
CREATE SCHEMA travail;

-- Create the schema named "temporary"
CREATE SCHEMA temporary;