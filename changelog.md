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

---
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

## 03-09-2026
### Reviewed graduation_rates_raw table (GRR) to determine which rows to keep/drop
- school_year - needed for longitudinal comparison 
- state - NOT NEEDED b/c all Montana
- leaid - needed for district comparison
- lea - needed for clarity of district comparison
- school - needed in case school-level analysis is completed
- nces_school_id - need in case school-level analysis is completed
- data_group - extraneous information only meaningful to Department of Education
- data_description - NOT NEEDED b/c the entire table is focused on ACGR
- value - needed, but needs to be renamed to more meaningful title (this is the primary metric - needed for table)
- denominator - needed b/c this is the enrollment count, needs renamed 
- numerator - NOT NEEDED - empty throughout table
- population- NOT NEEDED b/c listed as ‘All Students’ throughout table
- subgroup - Needed, shows important demographics
- group_characteristics - NOT NEEDED b/c empty values throughout chart
- age_grade - NOT NEEDED b/c empty values throughout chart
- academic_subject - NOT NEEDED b/c empty values throughout chart
- program_type - NOT NEEDED b/c empty values throughout chart
- outcome - NOT NEEDED b/c empty values throughout chart

### Investigated the 2020-21 row count discrepancy
- Confirmed discrepancy is at school level: 2020-21 has 2,044 school-level rows vs ~1,150 for other years       
- District-level counts are consistent across all years (~1,044–1,071 rows, 158–162 distinct districts)
- School and district counts are similar across years — same entities represented
- Subgroup categories identical across years (12 distinct values each)
- Hypothesis: 2020-21 includes a row per subgroup even when suppressed/missing; later years omit those rows
- Next: confirm hypothesis by comparing S/. counts by year or inspecting a single school across years

## 03-10-2026
### Confirmed step 2 hypothesis from graduation_rates_raw_cleaning_checklist.md
- Investigated KPS schools-level data: confirmed leaid 3015420, verified subgroup structure for Glacier High School and Flathead High School (12 rows per year, consistent across years)
- Confirmed hypothesis: 883 rows in 2020-2021 have value= '.' and denominator = 0 --> ie these rows carry no analytical value
- The 2020-2021 data contains all rows for subgroups even when there was no value (i.e. value = '.' and denominator = 0). 
- DECISION MADE: remove the rows from 2020-2021 data that have value = '.' and denominator = 0 (883 rows).

## 03-12-2026
### Made decision to use flag column to discern school, district, or state level data in graduation_rates_raw (step 3 graduation_rates_raw_cleaning_checklist)
- found 42 rows that did not have a school or lea listed, which are state level aggregated data
- the 42 rows have 14 each per school year where lea = 'Montana'
- DECISION MADE: Maintain single table with flag column to differentiate data. 2 tables means some of the information would be duplicated. Not necessary. A single table with a flag allows me to filter for school vs district data.

### step 4 of cleaning checklist!!!!!!!!! START HERE!!!!!!!!
- 

### step 5 of cleaning checklist - Determine how to handle suppressed values from graduation_rates_raw table
- identified that there are 1542 rows of district-level data in the table with suppressed values compared to 1639 rows with suppressed values at school-level using a CASE statement
- total rows for table without filters is 7486

## 03-16-2026
### Verified 'denominator' column in graduation_rates_raw is the ACGR (entering 9th-grade class ~4years prior), not enrollment
- Evidence: Flathead H S 2022-2023 total enrollment in mt_schools_clean is 3,101 vs denominator = 757 (~24% - consistent with one grade cohort out of four)
- Implication: I cannot us denominator as a proxy for district size; use mt_schools_clean enrollment for peer district comparisons

## 03-17-2026
### Queried Flathead H S enrollment to verify average enrollment in preparation to define 'similar size districts' for analysis
- Enrollment by year: 2022-2023: 3101; 2023-2024: 3105; 2024-2025: 2943
- Average over 3 years: 3,049
- found 2 new schools for 2024-2025 school year: Flathead Pace Academy (22) and Kalispell Rising Wolf Charter (11)
- Decision: exclude new schools from peer comparison - minimal enrollment and not consistent across years. 
- Decision: peer districts will be defined statewide by enrollment size only, not geography
- Decision: peer analysis scoped to high school level only (graduation rates are a HS metric only)
- Caveat noted: mt_schools_clean table based on years (2022-2025) and doesn't fully align with graduation_rates_raw table, based on year (2020 -2023) as 2023 was latest data available for graduation rates.

## 03-19-2026
### Identified peer districts for Flathead H S comparison
- Built a 3-step CTE to aggregate HS enrollment by district across years and compare to KPS (i.e. Flathead H S) benchmark (~3,049)
- Filtered to grade_lowest = '09' and grade_highest = '12' and total_enrollment > 100
- Initial approach used ±25% band (2,287–3,811); revised to natural break methodology after reviewing full district list
- Natural break: clear tier of Montana major city HS districts, then large cliff to Butte H S (1,285) and below
- Billings H S excluded as outlier (avg enrollment 5,459; 79% larger than KPS)
- Missoula H S included despite being just outside ±25% band (3,890; +27.5%) — natural peer given urban context
- PEER DISTRICTS DEFINED: Missoula H S, Great Falls H S, Bozeman H S, Helena H S
- Great Falls H S is closest true peer (avg enrollment 3,040; -0.3% vs KPS)