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

## 02-25-2026

### Investigated outliers in student_teacher_ratio
- Queried ratios > 50 and < 2 to identify suspicious values
- High ratio: Rise Charter & Distance HS (82:1) — distance learning school, legitimate data but should be excluded from county comparisons since student locations are unknown
- Low ratios: small rural Montana schools (1-4 students) — legitimate real-world data, not errors
- Special institutions: MT School for Deaf & Blind, Pine Hills Youth Correctional — low ratios expected given specialized populations
- Multiple appearances of same school name confirmed to be different school years, not duplicates

### Deleted 4 schools with 0 enrollment
- Schools with 0 students are not serving students and should be excluded from resource distribution analysis
- Verified 4 rows with SELECT before delete: CSD HS Rise Pathway Academy, Mount Ascension Learning Ac EL, Pondera Colony School, Rise Charter & Pathways EL
- Deleted inside a transaction, verified 0 rows returned before committing
- Row count: 2485 → 2481

## 02-26-2026

### Investigated non-traditional school classification
- Ran SELECT DISTINCT sch_type_text — 3 values: Regular School, Alternative School, Special Education School
- 12 schools classified as non-traditional (Alternative or Special Education)
- Investigated charter schools via LOWER(sch_name) LIKE '%charter%' — confirmed NCES classifies charters as Regular School
- Decision: sch_type_text sufficient for filtering in analysis queries — no additional boolean flag column needed

### Checked mt_schools_clean for duplicates
- Grouped by ncessch, sch_name, school_year with HAVING COUNT(*) > 1
- Zero duplicates found

## 02-27-2026

### Modified column names for mt_schools_clean table to make them more readable
- use ALTER TABLE montana_schools.mt_schools_clean RENAME current_column_name TO new_column_name
- columns renamed:
    - sch_name TO school_name
    - lea_name TO district_name
    - lcity TO city
    - lzip TO zip_code
    - student_count TO total_enrollment
    - teachers TO teachers_fte
    - sudent_teach_ratio TO student_teacher_ratio
    - free_reduced_lunch TO free_reduced_lunch_count
    - level TO school_level
    - gslo TO grade_lowest
    - gshi TO grade_highest
    -sy_status_text TO school_status
    - charter_text TO is_charter_school
    - sch_type_text TO school_type



## 03-02-2026

### Fixed free_reduced_lunch_count and poverty_pct calculations in mt_schools_clean table
- Discovered original CREATE TABLE subquery summed 'Free lunch qualified' + 'Reduced-price lunch qualified' rows from school_lunch table, but those rows have NULL student_count for suppressed/unreported data. This rendered nearly all lunch values Null (original method: only 1 valid school/year pair)
- Fix: pull from lunch_program = 'No Category Codes' / total_indicator = 'Education Unit Total' / data_group = 'Free and Reduced-price Lunch Table'
- Verified fix against C R Anderson (ncessch 300000500886): expected 311 for 2024-2025, confirmed correct
- Updated free_reduced_lunch_count and poverty_pct via UPDATE inside transaction
- Result: 1450 of 2481 rows now have lunch data (vs ~0 before); 1031 NULL rows are schools with suppressed or unreported data — expected

### Investigated NULL distribution in free_reduced_lunch_count
- Queried NULL rate by county and by enrollment band for 2024-2025
- Finding: NULLs are driven almost entirely by school size, not geography
    - Under 25 enrollment: 46.2% NULL
    - 25–99 enrollment: 4.3% NULL
    - 100+ enrollment: 0% NULL
- Flathead County: only 4.2% NULL (2 of 48 schools) — near-complete coverage
- High-null counties (e.g. Beaverhead 58%, Garfield 57%) have many tiny rural schools
- Analytical caveat: county-level poverty comparisons may understate poverty in rural counties where small school data is suppressed — should be noted in analysis

## 03-06-2026

### Imported graduation_rates_raw table
- Located graduation rates for Montana schools from https://eddataexpress.ed.gov/
- Most current year of data available was 2022-2023, so downloaded combined dataset for 2022-2023, 2021-2022, and 2020-2021
- 7486 total rows. Counts by school year: 2020-2021 (3048), 2021-2022 (2225), 2022-2023 (2213)

### Sanity checks on graduation_rates_raw
- Investigated row count discrepancy in 2020-2021 (37% more rows than other years)
- Initially suspected COVID-19 reporting anomalies or duplicates
- District-level row counts consistent across all three years: 2020-2021 (158), 2021-2022 (161), 2022-2023 (162) — data is clean and comparable
- Confirmed '.' values in 2020-2021 value column are school-level only — zero '.' values in district-level rows — no impact on district analysis
- Confirmed 92% school-level graduation rate coverage for high schools: 171 of 186 Montana high schools have school-level graduation rate data
- Decision: keep all three years including 2020-2021
- For analysis: filter to school = '' AND subgroup = 'All Students in LEA' for district-level comparisons; join on nces_sch_id = ncessch for school-level

## 03-07-2026

### Revised focus of analysis from Flathead County to Kalispell Public Schools, district 5
- discovered KPS spans 2 LEAIDs (3015450 and 3015420)
- identified feeder district complexity and how to handle it (provide caveat for analysis)
- rewrote business questions for updated focus
