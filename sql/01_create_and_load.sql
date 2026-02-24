-- =============================================
-- Data Ingestion Log
-- Project: Montana K-12 Education Analysis
-- Database: montana_education
-- Schema: montana_schools
-- Source: NCES Common Core of Data (CCD)
-- https://nces.ed.gov/ccd/files.asp
-- Date: February 2025
-- =============================================

-- =============================================
-- SCHEMA SETUP
-- =============================================

CREATE SCHEMA IF NOT EXISTS montana_schools;
SET search_path TO montana_schools;

-- =============================================
-- TABLE 1: school_directory
-- Source files: 2022-2023, 2023-2024, 2024-2025 school directory CSVs
-- Data scope: All states (full national file)
-- Import method: DBeaver wizard (2024-25, 2023-24), wizard (2022-23, COPY failed)
-- Columns: 65
-- Notes:
--   - First table created manually (hand-wrote CREATE TABLE)
--   - "union" is a SQL reserved word, must be quoted in queries
--   - Missing state_agency_no initially, added before first import
-- =============================================

-- Row counts:
-- 2022-2023: 102,268
-- 2023-2024: 102,274
-- 2024-2025: 102,178
-- Total: 306,720

-- =============================================
-- TABLE 2: school_characteristics
-- Source files: 2022-2023, 2023-2024, 2024-2025 school characteristics CSVs
-- Data scope: All states (full national file)
-- Import method: DBeaver wizard (auto-created table)
-- Columns: 17
-- Notes:
--   - Initial import failed: varchar(50) too short for nslp_status_text
--   - ALTERed nslp_status_text, virtual_text, virtual, nslp_status,
--     shared_time to varchar(200)
--   - Table initially created as "2024", renamed to school_characteristics
-- =============================================

-- Row counts:
-- 2022-2023: 100,571
-- 2023-2024: 100,458
-- 2024-2025: 100,237
-- Total: 301,266

-- =============================================
-- TABLE 3: school_membership
-- Source files: 2024-2025 full CSV, 2022-2023 and 2023-2024 MT-filtered CSVs
-- Data scope: Mixed — 2024-25 all states initially, later replaced with MT-only
-- Import method: DBeaver wizard
-- Columns: 18
-- Notes:
--   - Largest files (~2.2 GB each, ~11M rows per year)
--   - 2024-25 imported as full national file initially
--   - Switched to MT-only filtered files for 2022-23 and 2023-24 due to
--     file size slowing local machine
--   - 2024-25 later replaced with MT-only file for consistency
--   - Wizard auto-created extra "lea_name" column (not in source), dropped it
--   - SCHID was auto-detected as int4, altered to varchar(20)
--   - Used terminal grep to pre-filter: grep ",MT," source.csv >> mt_file.csv
-- =============================================

-- Row counts (MT-only after cleanup):
-- 2022-2023: 88,286
-- 2023-2024: 87,599
-- 2024-2025: 88,926
-- Total: 264,811

-- =============================================
-- TABLE 4: school_lunch
-- Source files: 2022-2023, 2023-2024, 2024-2025 MT-filtered CSVs
-- Data scope: Montana only (pre-filtered)
-- Import method: DBeaver wizard
-- Columns: 17
-- Notes:
--   - Table initially created as "2024", renamed to school_lunch
--   - 2023-2024 accidentally imported from full CSV first time, deleted and
--     reimported from MT file
--   - Many NULL values in student_count — normal NCES suppression for
--     small groups and non-participating schools
-- =============================================

-- Row counts:
-- 2022-2023: 3,685
-- 2023-2024: 3,710
-- 2024-2025: 3,810
-- Total: 11,205

-- =============================================
-- TABLE 5: school_staff
-- Source files: 2022-2023, 2023-2024, 2024-2025 school staff CSVs
-- Data scope: All states (files small enough at 14 MB each)
-- Import method: DBeaver wizard
-- Columns: 15
-- Notes:
--   - TEACHERS column is NUMERIC (FTE — includes decimals like 43.50)
--   - Initial import failed: ST_SCHID varchar(20) too short for some
--     state IDs (e.g., IL IDs are 34 chars), bumped to varchar(60)
-- =============================================

-- Row counts:
-- 2022-2023: 100,571
-- 2023-2024: 100,458
-- 2024-2025: 100,237
-- Total: 301,266

-- =============================================
-- TABLE 6: district_directory
-- Source files: 2022-2023, 2023-2024, 2024-2025 district directory CSVs
-- Data scope: All states (files small at 7.7 MB each)
-- Import method: DBeaver wizard
-- Columns: 58
-- =============================================

-- Row counts:
-- 2022-2023: 19,714
-- 2023-2024: 19,637
-- 2024-2025: 19,630
-- Total: 58,981

-- =============================================
-- TABLE 7: district_membership
-- Source files: 2022-2023, 2023-2024, 2024-2025 MT-filtered CSVs
-- Data scope: Montana only (pre-filtered, originals ~620 MB each)
-- Import method: DBeaver wizard
-- Columns: 15
-- =============================================

-- Row counts:
-- 2022-2023: 66,233
-- 2023-2024: 66,054
-- 2024-2025: 65,517
-- Total: 197,804

-- =============================================
-- TABLE 8: district_staff
-- Source files: 2022-2023, 2023-2024, 2024-2025 MT-filtered CSVs
-- Data scope: Montana only (pre-filtered, originals ~57 MB each)
-- Import method: DBeaver wizard
-- Columns: 13
-- =============================================

-- Row counts:
-- 2022-2023: 10,936
-- 2023-2024: 10,911
-- 2024-2025: 10,836
-- Total: 32,683

-- =============================================
-- TABLE 9: mt_cities_counties
-- Source file: MT Counties_Full Data_data.csv (Montana Data Portal)
-- Data scope: Montana only
-- Import method: DBeaver wizard (UTF-16LE encoding, tab delimiter)
-- Columns: 5
-- Notes:
--   - File was UTF-16LE encoded — set encoding in DBeaver import wizard
--   - Tab-delimited, not comma-delimited
--   - 593 of 642 rows have null zip codes — verified against source file, not an import error
--   - Only 1 city appeared in multiple counties (Lakeside: Flathead co+ Lewis and Clark co)
-- =============================================

-- Row counts:
-- 642 rows

-- =============================================
-- POST-IMPORT CLEANUP
-- =============================================

-- Renamed all uppercase column names to lowercase across all 8 tables
-- (132 columns total) to avoid quoting issues in queries.
-- Tables created manually (school_directory, school_characteristics)
-- had lowercase columns. Tables created by DBeaver wizard had uppercase.
-- Standardized to lowercase for consistency.

-- =============================================
-- FILE FILTERING
-- =============================================

-- Large files (>50 MB) were pre-filtered to Montana-only using terminal:
--   head -1 source.csv > source-MT.csv
--   grep ",MT," source.csv >> source-MT.csv
--
-- Filtered files created:
--   *-school-membership-MT.csv (2.2 GB -> ~16 MB)
--   *-school-lunch-MT.csv (85 MB -> ~650 KB)
--   *-district-membership-MT.csv (620 MB -> ~10 MB)
--   *-district-staff-MT.csv (57 MB -> ~1.2 MB)
