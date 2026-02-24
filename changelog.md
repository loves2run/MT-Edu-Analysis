# Changelog 

## 02-16-2026

### Started data cleaning phase
- Explored school_directory columns, narrowed 65 columns to ~14 needed for analysis
- Used JOIN to combine data from school_membership and school_staff into school_directory
    - school_directory (school_name, location, type)
    - school_membership (enrollment via total_indicator = 'Education Unit Total')
    - school_staff (teachers FTE)
- Calculated student_teacher_ratio: ROUND(student_count / teachers, 1)
- Filter: Montana only, 2024-2025, teachers > 0
- Next: add more columns, join lunch table, handle NULL values, create mt_schools_clean table

### Created mt_schools_clean table
- Joined school_directory, school_membership, school_staff and school_lunch tables
- Used left join b/c some schools may not have lunch data and we wanted to verify all data was included in results
- derived student_teacher ratio by dividing student count by number of teachers
- derived poverty_pct by dividing free_reduced_lunch count by student_count
- 2485 total rows

## 02-20-2026 

### Explored data sources for combined MT cities/counties dataset
- investigated MT cities/counties/zip data sources
- found MT counties dataset on data.montana.gov with city, county, zip, city type, FIPS

### Imported mt_cities_counties reference table
- Source: MT Counties_Full Data_data.csv (Montana Data Portal)
- 642 rows, tab-separated, UTF-16LE encoded
- Imported via DBeaver wizard with UTF-16LE encoding and tab delimiter
- Verified 593 null zip codes match original source file - not an import error
- only 2 cities appear in multiple counties (Lakeside: Flathead + Lewis and Clark)

### Next: add county column to mt_schools_clean

## 02-21-2026

### Data quality checks on mt_cities_counties
- Ran SELECT DISTINCT county — returned 58 counties instead of expected 56
- Verified Montana has 56 counties via census.gov
- Found two casing inconsistencies: 'Lewis And Clark' vs 'Lewis and Clark', 'Mccone' vs 'McCone'
- Standardized both using UPDATE inside a transaction — verified 56 distinct counties after commit

### Removed erroneous Lakeside row
- Lakeside appeared in both Flathead and Lewis and Clark counties
- Verified via mtcounties.org that Lakeside is solely in Flathead County
- Deleted Lewis and Clark row — table now has 641 rows

### Identified 4 cities in mt_schools_clean missing from mt_cities_counties
- McLeod (Sweet Grass, 59052, FIPS 097)
- E Glacier Park (Glacier, 59434, FIPS 035)
- St Ignatius (Lake, 59865, FIPS 047)
- St Regis (Mineral, 59866, FIPS 061)
- Sources: mtcounties.org, dphhs.mt.gov FIPS codes, dojmt.gov zip codes

## 02-24-2026

### Completed county column addition to mt_schools_clean
- Verified 4 city INSERTs worked (McLeod, E Glacier Park, St Ignatius, St Regis)
- Checked for city name mismatches: SELECT DISTINCT lcity WHERE lcity NOT IN mt_cities_counties — returned 0 rows
- Added county VARCHAR(50) column via ALTER TABLE
- Populated county via UPDATE joining mt_schools_clean.lcity to mt_cities_counties.city

### Verified county column population
- County distribution query: all 56 Montana counties present, counts sum to 2485 — no missing schools
- NULL check: 0 rows — every school received a county value
- Flathead spot check: Bigfork, Kalispell, Whitefish all mapping correctly to Flathead county