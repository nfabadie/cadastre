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

-- Create the table to save the zones names and geom of each areas
CREATE TABLE public.zones_per_areas(id_zone character varying(10), geom geometry(POLYGON, 2154), id_area integer);