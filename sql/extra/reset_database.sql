DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

-- Rebuild everything
\i ../schema.sql
\i ../sample_data.sql
