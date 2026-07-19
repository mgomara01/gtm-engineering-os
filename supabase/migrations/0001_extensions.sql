create extension if not exists pgcrypto;
create extension if not exists citext;
-- Both genuinely missing (not a naming issue): 0011_entity_resolution.sql uses
-- gin_trgm_ops/similarity() (needs pg_trgm) and unaccent() (needs the unaccent
-- extension), but neither extension was ever enabled anywhere in the original migrations.
create extension if not exists pg_trgm;
create extension if not exists unaccent;
create schema if not exists platform;
create schema if not exists configuration;
create schema if not exists entities;
create schema if not exists ingestion;
create schema if not exists intelligence;
create schema if not exists scoring;
create schema if not exists gtm;
create schema if not exists implementation;
create schema if not exists agents;
create schema if not exists analytics;
create schema if not exists governance;
create schema if not exists integrations;
