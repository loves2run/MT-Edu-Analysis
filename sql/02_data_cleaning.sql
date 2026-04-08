-- ============================================================
-- SECTION 1: mt_schools_clean
-- ============================================================

-- =============================================
-- STEP 1: Create mt_schools_clean table
-- Joins school_directory, school_membership, school_staff, school_lunch
-- Filter: Montana only, 2024-2025, teachers > 0
-- =============================================

-- working query: school directory + membership + staff joined
-- joins 3 tables to get school info, enrollment, and teachers for Montana
-- TODO: add more columns, join, lunch, handle NULLs, turn into CREATE TABLE

create table mt_schools_clean AS
select d.ncessch, d.leaid, d.sch_name, d.lea_name,
    d.lcity, d.lzip, d.level, d.gslo, d.gshi, 
    d.sch_type_text, d.charter_text, d.sy_status_text,
    d.school_year, m.student_count, s.teachers,
    ROUND(m.student_count / s.teachers, 1) as student_teach_ratio,
    l.free_reduced_lunch,
  	ROUND(100.0 * l.free_reduced_lunch / m.student_count, 1) as poverty_pct
from school_directory d
join school_membership m
    on d.ncessch = m.ncessch 
    and d.school_year = m.school_year 
join school_staff s
    on d.ncessch  = s.ncessch 
    and d.school_year = s.school_year 
left join (
select ncessch, school_year,
    SUM(student_count) as free_reduced_lunch 
from montana_schools.school_lunch
where lunch_program in ('Free lunch qualified', 'Reduced-price lunch qualified')
group by ncessch, school_year
) l
    on d.ncessch = l.ncessch
    and d.school_year = l.school_year
where d.st = 'MT'
    and m.total_indicator = 'Education Unit Total'
    and s.teachers > 0;

-- =============================================
-- STEP 2: Add county column to mt_schools_clean
-- Source: mt_cities_counties (Montana Data Portal)
-- Join on city name match between mt_schools_clean.lcity and mt_cities_counties.city
-- Lakeside duplicate resolved by deleting erroneous Lewis and Clark row from mt_cities_counties
-- =============================================

-- Standardize county name casing in mt_cities_counties
BEGIN;

UPDATE montana_schools.mt_cities_counties
SET county = 'Lewis and Clark'
WHERE county = 'Lewis And Clark';

UPDATE montana_schools.mt_cities_counties
SET county = 'McCone'
WHERE county = 'Mccone';

-- verify 56 distinct counties before committing
SELECT DISTINCT county
FROM montana_schools.mt_cities_counties
ORDER BY county ASC;

COMMIT;

-- DELETE erroneous Lakeside row (Lewis and Clark — verified not correct via mtcounties.org)
DELETE FROM montana_schools.mt_cities_counties
WHERE city = 'Lakeside' AND county != 'Flathead';

-- Add county column to mt_schools_clean
ALTER TABLE montana_schools.mt_schools_clean
ADD county VARCHAR(50);

-- INSERT 4 cities missing from mt_cities_counties
-- Sources: mtcounties.org, dphhs.mt.gov (FIPS), dojmt.gov (zip codes)
INSERT INTO montana_schools.mt_cities_counties
    (city, county, zip_code, city_type, county_fips_code)
VALUES
    ('McLeod', 'Sweet Grass', '59052', NULL, '097'),
    ('E Glacier Park', 'Glacier', '59434', NULL, '035'),
    ('St Ignatius', 'Lake', '59865', NULL, '047'),
    ('St Regis', 'Mineral', '59866', NULL, '061');

-- Populate county column in mt_schools_clean from mt_cities_counties
UPDATE montana_schools.mt_schools_clean
SET county = mcc.county
FROM montana_schools.mt_cities_counties mcc
WHERE lcity = mcc.city;

-- =============================================
-- STEP 3: Verify county column population
-- =============================================

-- County distribution — confirm all 56 counties present and row count = 2485
SELECT county, COUNT(*) as school_count
FROM montana_schools.mt_schools_clean
GROUP BY county
ORDER BY school_count DESC;

-- NULL check — confirm every school received a county value
SELECT lcity, COUNT(*) as count
FROM montana_schools.mt_schools_clean
WHERE county IS NULL
GROUP BY lcity
ORDER BY count DESC;

-- Flathead spot check
SELECT lcity, sch_name, county
FROM montana_schools.mt_schools_clean
WHERE county = 'Flathead'
LIMIT 10;

-- =============================================
-- STEP 4: Data quality checks on mt_schools_clean
-- =============================================

-- Check for duplicates — ncessch + school_year should be unique
SELECT ncessch, sch_name, school_year, COUNT(*)
FROM montana_schools.mt_schools_clean
GROUP BY ncessch, school_year, sch_name
HAVING COUNT(*) > 1;
-- Result: 0 duplicates found

-- Check for outliers in student_teacher_ratio
-- High ratio (>50) or low ratio (<2) may indicate data issues
SELECT sch_name, school_year, student_count, teachers, sudent_teach_ratio
FROM montana_schools.mt_schools_clean
WHERE sudent_teach_ratio > 50
   OR sudent_teach_ratio < 2
ORDER BY sch_name ASC;
-- Result: high ratios = distance learning schools (legitimate)
--         low ratios = small rural schools and specialized institutions (legitimate)
--         Note: Rise Charter & Distance HS (82:1) should be excluded from county comparisons

-- Check for 0-enrollment schools
SELECT sch_name, school_year, student_count, teachers, sudent_teach_ratio
FROM montana_schools.mt_schools_clean
WHERE student_count = 0
ORDER BY sch_name ASC;
-- Result: 4 rows found

-- Delete 0-enrollment schools
-- Rationale: schools with 0 students are not serving students and should be excluded
BEGIN;

DELETE FROM montana_schools.mt_schools_clean
WHERE student_count = 0;

-- Verify 0 rows remain before committing
SELECT sch_name, school_year, student_count
FROM montana_schools.mt_schools_clean
WHERE student_count = 0;

COMMIT;

-- Confirm row count: 2485 → 2481
SELECT COUNT(*) FROM montana_schools.mt_schools_clean;

-- Investigate non-traditional school classification
SELECT DISTINCT sch_type_text
FROM montana_schools.mt_schools_clean;

-- Count by school type
SELECT sch_type_text, COUNT(*) as school_count
FROM montana_schools.mt_schools_clean
GROUP BY sch_type_text
ORDER BY school_count DESC;

-- Review non-traditional schools
SELECT sch_name, lea_name, sch_type_text
FROM montana_schools.mt_schools_clean
WHERE sch_type_text IN ('Alternative School', 'Special Education School');

-- Check charter schools — confirm NCES classifies as Regular School
SELECT sch_name, lea_name, sch_type_text
FROM montana_schools.mt_schools_clean
WHERE LOWER(sch_name) LIKE '%charter%'
   OR LOWER(lea_name) LIKE '%charter%';
-- Result: charters classified as Regular School by NCES — no additional flag needed
-- Use sch_type_text to filter non-traditional schools in analysis queries as needed


-- ====================================================
-- STEP 5: Rename columns on mt_schools_clean
-- ====================================================
-- renamed columns for readability

alter table montana_schools.mt_schools_clean
	rename sch_name to school_name;
alter table montana_schools.mt_schools_clean
	rename lea_name to district_name;

alter table montana_schools.mt_schools_clean
	rename lcity to city;

alter table montana_schools.mt_schools_clean
	rename lzip to zip_code;

alter table montana_schools.mt_schools_clean
	rename student_count to total_enrollment;

alter table montana_schools.mt_schools_clean
	rename teachers to teachers_fte;

alter table montana_schools.mt_schools_clean
	rename sudent_teach_ratio to student_teacher_ratio;

alter table montana_schools.mt_schools_clean
	rename	free_reduced_lunch to free_reduced_lunch_count;

alter table montana_schools.mt_schools_clean
	rename level to school_level;

alter table montana_schools.mt_schools_clean
	rename gslo to grade_lowest;

alter table montana_schools.mt_schools_clean 
	rename gshi to grade_highest;

alter table montana_schools.mt_schools_clean
	rename sy_status_text to school_status;

alter table montana_schools.mt_schools_clean
	rename charter_text to is_charter_school;

alter table montana_schools.mt_schools_clean
	rename sch_type_text to school_type;


-- ====================================================
-- STEP 6: Fix free_reduced_lunch_count and poverty_pct
-- ====================================================
-- Original CREATE TABLE summed 'Free lunch qualified' + 'Reduced-price lunch
-- qualified' rows from school_lunch, but student_count is NULL for suppressed
-- data — leaving nearly all lunch values NULL.
-- Fix: use the 'No Category Codes' / 'Education Unit Total' row which contains
-- the pre-summed total and is more broadly reported.

-- Verification: confirm pre-summed row exists for a known school
-- C R Anderson (300000500886) should return 311 for 2024-2025
select ncessch, school_year, student_count
from montana_schools.school_lunch
where lunch_program = 'No Category Codes'
    and total_indicator = 'Education Unit Total'
    and data_group = 'Free and Reduced-price Lunch Table'
    and ncessch = '300000500886';

-- Update lunch columns using pre-summed total row
begin;

update montana_schools.mt_schools_clean m
set
    free_reduced_lunch_count = l.total_lunch,
      poverty_pct = ROUND(100.0 * l.total_lunch / m.total_enrollment, 1)
from (
    select ncessch, school_year, student_count AS total_lunch
    from montana_schools.school_lunch
    where lunch_program = 'No Category Codes'
        and total_indicator = 'Education Unit Total'
        and data_group = 'Free and Reduced-price Lunch Table'
        and student_count IS NOT NULL
) l
where m.ncessch = l.ncessch
    and m.school_year = l.school_year;

-- Verify counts before committing
-- Expect: total=2481, lunch_not_null=1450, poverty_not_null=1450
select
    COUNT(*) as total_rows,
    COUNT(free_reduced_lunch_count) as lunch_not_null,
    COUNT(*) - COUNT(free_reduced_lunch_count) as lunch_null,
    COUNT(poverty_pct) as poverty_not_null,
    COUNT(*) - COUNT(poverty_pct) as poverty_null
from montana_schools.mt_schools_clean;

commit;

-- ====================================================
-- STEP 7: Investigate NULL distribution in lunch data
-- ====================================================
-- Finding: NULLs are driven by school size, not geography
-- Under 25 enrollment: 46.2% NULL
-- 25-99 enrollment: 4.3% NULL
-- 100+ enrollment: 0% NULL
-- Analytical caveat: county-level poverty comparisons may understate poverty
-- in rural counties where small school data is suppressed

-- NULL rate by county
SELECT
    county,
    COUNT(*) AS total_schools,
    COUNT(free_reduced_lunch_count) AS lunch_reported,
    COUNT(*) - COUNT(free_reduced_lunch_count) AS lunch_null,
    ROUND(100.0 * (COUNT(*) - COUNT(free_reduced_lunch_count)) / COUNT(*), 1) AS pct_null
FROM montana_schools.mt_schools_clean
WHERE school_year = '2024-2025'
GROUP BY county
ORDER BY pct_null DESC;

-- NULL rate by enrollment band
SELECT
    CASE
        WHEN total_enrollment < 25 THEN '1. Under 25'
        WHEN total_enrollment < 100 THEN '2. 25-99'
        WHEN total_enrollment < 500 THEN '3. 100-499'
        ELSE '4. 500+'
    END AS enrollment_band,
    COUNT(*) AS total_schools,
    COUNT(free_reduced_lunch_count) AS lunch_reported,
    COUNT(*) - COUNT(free_reduced_lunch_count) AS lunch_null,
    ROUND(100.0 * (COUNT(*) - COUNT(free_reduced_lunch_count)) / COUNT(*), 1) AS pct_null
FROM montana_schools.mt_schools_clean
WHERE school_year = '2024-2025'
GROUP BY enrollment_band
ORDER BY enrollment_band;

-- ============================================================
-- SECTION 2: graduation_rates_raw → graduation_rates_clean
-- ============================================================

-- ====================================================
-- STEP 1: Column selection for graduation_rates_clean
-- ====================================================
-- columns dropped from graduation_rates_raw:
-- state                - constant (all Montana)
-- data_group           - internal DOE categorization, not analytically useful
-- data_description     - entire table is ACGR, column adds no information
-- numerator            - all NULL throughout table
-- population           - constant (‘All Students’)
-- group_characteristics - all empty
-- age_grade            - all empty
-- academic_subject     - all empty
-- program_type         - all empty
-- outcome              - all empty

-- ====================================================
-- STEP 2: Investigate 2020-21 school-level row count discrepancy
-- ====================================================
-- Finding: discrepancy is entirely at school level
-- District-level rows are consistent: 2020-21 (1044), 2021-22 (1071), 2022-23 (1063)
-- School-level rows differ significantly: 2020-21 (2044), 2021-22 (1154), 2022-23 (1150)
-- District and school counts are similar across years — same entities represented
-- Subgroup categories identical across years (12 distinct values each year)
-- Hypothesis: 2020-21 includes a row per subgroup even when suppressed/missing;
--             later years omit rows where a subgroup has no reportable data
-- ~12.2 rows/school in 2020-21 vs ~6.75 rows/school in 2021-22 supports this
-- Next: confirm by comparing S/. value counts by year or inspecting a single school

-- District-level row counts by year
SELECT school_year, COUNT(*)
FROM montana_schools.graduation_rates_raw
WHERE school = ‘’
GROUP BY school_year
ORDER BY school_year;

-- School-level row counts by year
SELECT school_year, COUNT(*)
FROM montana_schools.graduation_rates_raw
WHERE school <> ‘’
GROUP BY school_year;

-- Distinct district (leaid) counts by year — district and school level
SELECT school_year, COUNT(DISTINCT leaid)
FROM montana_schools.graduation_rates_raw
WHERE school = ‘’
GROUP BY school_year
ORDER BY school_year;

SELECT school_year, COUNT(DISTINCT leaid)
FROM montana_schools.graduation_rates_raw
WHERE school <> ‘’
GROUP BY school_year
ORDER BY school_year;

-- Distinct school counts by year
SELECT school_year, COUNT(DISTINCT school)
FROM montana_schools.graduation_rates_raw
GROUP BY school_year
ORDER BY school_year;

-- Distinct subgroup counts by year (school-level)
SELECT school_year, COUNT(DISTINCT subgroup)
FROM montana_schools.graduation_rates_raw
WHERE school <> ‘’
GROUP BY school_year
ORDER BY school_year;

-- Distinct lea counts by year — district and school level
SELECT school_year, COUNT(DISTINCT lea)
FROM montana_schools.graduation_rates_raw
WHERE school = ‘’
GROUP BY school_year
ORDER BY school_year;

SELECT school_year, COUNT(DISTINCT lea)
FROM montana_schools.graduation_rates_raw
WHERE school <> ‘’
GROUP BY school_year
ORDER BY school_year;

-- Confirm hypothesis: verify dot rows have denominator = 0
-- Result: 883 rows with value='.' all have denominator=0 — zero students, not missing data
select value, denominator, COUNT(*)
from montana_schools.graduation_rates_raw
where school_year = '2020-2021'
    and school <> ''
group by value, denominator
order by value;

-- Decision: these rows will be excluded from graduation_rates_clean
-- Rationale: denominator=0 means no students in subgroup — not a graduation rate,
-- not suppressed data. Inconsistent with later years which omit these rows entirely.

-- Decision: use flag column to distinguish school-level, district-level and state-level rows        
-- TO DO: Add 'data_level' column in graduation_rates_clean using CASE:
--   WHEN leaid is null THEN 'state'                                                                 
--   WHEN school = '' THEN 'district'
--   ELSE 'school'

select
	case 
        when leaid is null then 'state'
		when school = '' then 'district'
        else 'school'
	end as data_level,
	count(*) as suppressed_rows
from montana_schools.graduation_rates_raw grr 
where value = 'S'
group by data_level;

-- **** step 4 goes here!!!!******



-- step 5 from graduation_rates_raw_cleaning_checklist
-- suppressed rows at district vs school level vs total rows in table unfiltered
-- num_dist_rows =1542, num_school_rows =1639, total_rows =7486

-- ====================================================
-- KPS Flathead H S enrollment benchmark (03-17-2026)
-- Used to define peer districts for graduation rate comparison
-- ====================================================
-- Note: denominator in graduation_rates_raw is the adjusted cohort (~1 grade),
-- NOT total enrollment. Verified 03-16-2026: Flathead H S 2022-23 total enrollment
-- = 3,101 vs denominator = 757 (~24% — consistent with one grade cohort out of four).
-- Use mt_schools_clean enrollment for peer district size matching.

-- Flathead H S enrollment by year
-- Excludes Flathead Pace Academy (22) and Kalispell Rising Wolf Charter (11) —
-- both new in 2024-2025 only, too small and inconsistent across years for benchmarking.
-- They account for only ~20% of the 2024-25 enrollment drop; drop is real.
-- Results: 2022-2023: 3101, 2023-2024: 3105, 2024-2025: 2943
-- 3-year average: ~3,049 — used as KPS size benchmark for peer matching
select
    school_year,
    SUM(total_enrollment) as total_enrollment
from montana_schools.mt_schools_clean
where
    school_name = 'Flathead High School'
    or school_name = 'Glacier High School'
group by school_year
order by school_year;

-- Same query including the two small new schools for reference
-- Results: 2022-2023: 3101, 2023-2024: 3105, 2024-2025: 2976
select
    school_year,
    SUM(total_enrollment) as total_enrollment
from montana_schools.mt_schools_clean
where
    district_name = 'Flathead H S'
group by school_year
order by school_year;

-- ====================================================
-- PEER DISTRICT IDENTIFICATION (03-19-2026)
-- Identifies Montana HS districts comparable to Flathead H S by enrollment size
-- ====================================================
-- Methodology: natural break approach — Montana major city HS districts form a
-- clear tier. Billings H S excluded as outlier (+79%). Missoula H S included
-- despite being just outside ±25% band (+27.5%) — natural urban peer.
-- Peer districts: Missoula H S, Great Falls H S, Bozeman H S, Helena H S
-- Great Falls H S is closest true peer (-0.3% vs KPS benchmark of 3,049)

-- 3/19/26: working on a CTE to solve for average aggregate enrollment by school district
/*Peer districts were defined as Montana high school districts serving
 * similarly-sized urban populations. Billings was excluded as an outlier (79% larger than KPS).
 * The remaining four major city districts — Missoula, Great Falls, Bozeman, and Helena — form a natural peer group.
*/
with hs_only as (
    select *
    from montana_schools.mt_schools_clean
    where
        grade_lowest = '09'
        and grade_highest = '12'
        and total_enrollment > 100
),

district_by_year as (
    select
        school_year,
        district_name,
        SUM(total_enrollment) as total_enrollment
    from hs_only
    group by
        district_name,
        school_year
),

district_avg as (
    select
        district_name,
        ROUND(AVG(total_enrollment), 0) as avg_enrollment
    from district_by_year
    group by district_name
)

select
    *,
    ROUND(100.0 * (avg_enrollment - 3050) / 3050, 1) as pct_diff_from_fhs
from district_avg
order by avg_enrollment desc
limit 10;


-- ====================================================
-- Created graduation_rates_clean table (04-02-2026)
-- ====================================================
-- table created on 4/2/26
create table montana_schools.graduation_rates_clean(
	school_year VARCHAR(50),
	leaid INTEGER,
	lea VARCHAR(50),
	school VARCHAR(50),
	nces_school_id VARCHAR(50),
	school_or_district VARCHAR(10),   --to differentiate school-level vs district-level data
	grad_rate_clean INTEGER, -- cleaned/transformed values from graduation_rates_raw
	grad_rate_raw varchar(50),  -- raw value column from graduationa_rates_raw
	denominator INTEGER,
	subgroup VARCHAR(50)
);

-- updated table on 4/2/26 to change name of denominator column 
	-- renamed to acgr_cohort_size to clarify what it is

alter table montana_schools.graduation_rates_clean 
rename column denominator to acgr_cohort_size;

-- updated table on 4/2/26 to change grad_rate_clean column
	-- from INTEGER to REAL (ie. floating point number) due
	-- to error attempting to run INSERT INTO query
    -- error occurred due to floating point number values
    -- in the original raw dataset could not be converted to integers
alter table montana_schools.graduation_rates_clean 
alter column grad_rate_clean type real;


/*
 * This query inserts values into new graduation_rates_clean table.
 * The INSERT INTO query below first filters out the rows with
 	* value = '.' as previously decided. 
 * Conditional logic used to populate school_or_district column.
 * Added column for grad_rate_clean
 	* Used regex to populate column with just those rows from
 	* value column of graduation_rates_raw that contained full numbers
 	* (e.g. '56%') and then removed the '%' and converted to INTEGER.
 	* The remaining values were transformed to NULL.
 * Separate column (grad_rate_raw). It preserves the original raw string from the     
 	* value column when the value could not be converted to a number (bands, suppressed, etc).
 * leaid and denominator columns CAST to integer
 */
insert into montana_schools.graduation_rates_clean (
	school_year,
	leaid,
	lea,
	school,
	nces_school_id,
	school_or_district,
	grad_rate_clean,
	grad_rate_raw,
	acgr_cohort_size,
	subgroup
)
select
	school_year,
	CAST(leaid as INTEGER),
	lea,
	school,
	nces_school_id,
	case 
		when school = '' then 'district'
		else 'school'
	end as school_or_district,
	CAST(case 
			when value ~ '[-><=S]' then null
			else REPLACE(value, '%', '')
		end as REAL) as grad_rate_clean,
	case
		when value ~ '[-><=S]' then value
		else NULL
	end as grad_rate_raw,
	cast(denominator as INTEGER) as acgr_cohort_size,
	subgroup
from montana_schools.graduation_rates_raw
where value <> '.';

/*
==========================================================
Verification of graduation_rates_clean table
==========================================================
 */

-- 4/2/26: values now inserted into graduation rates clean. 
-- 883 rows deleted from graduation_rates_raw for value 
	-- equal to '.' --> expected and found 6603 rows in
	-- graduation_rates_clean table from original 7486 rows
	-- of raw table
select COUNT(*) as num_rows
from montana_schools.graduation_rates_raw;

select COUNT(*) as rows_deleted
from montana_schools.graduation_rates_raw
where value = '.';

select COUNT(*) as num_rows
from montana_schools.graduation_rates_clean;

-- 4/2/26: REMINDER!!! statewide data delineated by LEAID of NULL!
select *
from montana_schools.graduation_rates_clean
where leaid is null;

select 
	school_year,
	COUNT(school_year)
from montana_schools.graduation_rates_clean
where leaid is null
group by school_year
order by school_year;

-- 4/2/26: Verify conditional logic for school_district column
-- returned 0 rows for both queries
select
	school_year,
	COUNT(school_year)
from montana_schools.graduation_rates_clean
where 
	school = ''
	and school_or_district <> 'district'
group by school_year;

select 
	school_year,
	COUNT(school_year)
from montana_schools.graduation_rates_clean
where 
	school <> ''
	and school_or_district <> 'school'
group by school_year;



-- Verify grad_rates_clean and grad_rates_raw columns
-- To be accurate the clean and raw columns should not 
	-- be null at same time
-- 0 rows returned

select *
from montana_schools.graduation_rates_clean 
where
	(grad_rate_clean is null
	and grad_rate_raw is null)
	or (grad_rate_clean is not null 
	and grad_rate_raw is not null);

-- Ran spot check for Flathead High School to verify grad_rate_raw
	-- and grad_rate_clean values were mutually exclusive (i.e. not null
	-- at same time).
-- Query also confirms that regex worked properly: 
	-- only integers in grad_rate_clean
	-- Values with symbols like 'S', '>', '<', '-' only appear in grad_rate_raw
	-- '%' symbol stripped from grad_rate_clean
select 	
	school_year,
	lea,
	school,
	grad_rate_clean,
	grad_rate_raw,
	acgr_cohort_size,
	subgroup
from montana_schools.graduation_rates_clean
where
	school_year = '2022-2023'
	and school like '%Flathead%';



-- Verify values for acgr_cohort_size
-- 0 rows returned; row is clean
select *
from montana_schools.graduation_rates_clean
where 
	acgr_cohort_size is null
	or acgr_cohort_size = 0;
