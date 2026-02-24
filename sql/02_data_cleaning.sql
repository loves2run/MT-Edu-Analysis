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