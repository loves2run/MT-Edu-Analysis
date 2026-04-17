-- ============================================================
-- SECTION 1: KPS vs Peer Districts — Graduation Rate Analysis
-- ============================================================

-- ====================================================
-- Graduation rates for all students by district (04-17-2026)
-- Peer district comparison — all 3 years
-- ====================================================
--Findings:
--  Bozeman H S	    3004590	    89.0	87.0	90.0
--  Helena H S	    3013830	    87.0	86.0	87.0
--  Missoula H S	3018540	    89.0	86.0	85.0
--  Great Falls H S	3013050	    82.0	83.0	83.0
--  Flathead H S	3015420	    84.0	83.0	81.0
-- Flathead and Missoula graduation rates are falling, 3% & 4% respectively across the 3 years
-- Flathead graduation rate is considerably worse than 3 of 4 peer districts in 2022-2023
-- Future analysis: 
    -- analyze several more years of data to determine if grad rates are continuing to fall for KPS
    -- analysis would be stronger if annual assessment data and chronic absenteeism data were available for use

select
	leaid,
	lea,
	MAX(
		case
			when peer_grad_rates.school_year = '2020-2021' 
			then peer_grad_rates.grad_rate_clean
			else NULL
		end
		
	) as grad_rate_21,
	MAX(
		case
			when peer_grad_rates.school_year = '2021-2022'
			then peer_grad_rates.grad_rate_clean
			else NULL
		end
	) as grad_rate_22,
	MAX(
		case
			when peer_grad_rates.school_year = '2022-2023'
			then peer_grad_rates.grad_rate_clean
			else NULL
		end
		
	) as grad_rate_23
from 
	(select
		school_year,
        lea,
        leaid,
        grad_rate_clean,
        grad_rate_raw,
        subgroup,
        acgr_cohort_size
	from montana_schools.graduation_rates_clean
	where 
		school_or_district = 'district'
		and subgroup = 'All Students in LEA'
		and leaid in (
			3004590,  -- Bozeman H S
            3015420,  -- Flathead H S
            3013050,  -- Great Falls H S
            3013830,  -- Helena H S
            3018540   -- Missoula H S
		)
	) peer_grad_rates
group by 
	leaid,
	lea
order by grad_rate_23 desc;


-- ====================================================
-- Economically Disadvantaged subgroup (04-13-2026)
-- Peer district comparison — all 3 years
-- ====================================================
-- Findings (2022-23):
--   Missoula H S:    73.0%  (exact, cohort 374)
--   Great Falls H S: 69.0%  (exact, cohort 370)
--   Flathead H S:    65.0%  (exact, cohort 306)
--   Helena H S:      65-69% (banded, cohort 180) — all 3 years banded
--   Bozeman H S:     65-69% (banded, cohort 76)  — all 3 years banded
-- Flathead trend: 72% (2020-21) → banded 65-69% (2021-22) → 65% (2022-23) — ~7-point decline
-- Decision: no midpoints for banded values; Helena and Bozeman excluded from numeric comparison
-- Caveat: both fall in the same 65-69% range as Flathead's exact 65% — cannot rank precisely

select
    school_year,
    lea,
    leaid,
    grad_rate_clean,
    grad_rate_raw,
    subgroup,
    acgr_cohort_size
from montana_schools.graduation_rates_clean
where
    subgroup like '%Economically Disadvantaged%'
    and school_or_district = 'district'
    and leaid in (
        3004590,  -- Bozeman H S
        3015420,  -- Flathead H S
        3013050,  -- Great Falls H S
        3013830,  -- Helena H S
        3018540   -- Missoula H S
    )
order by school_year, leaid;


-- ============================================================
-- SECTION 2: KPS vs Peer Districts — Resource Analysis
-- ============================================================

-- ====================================================
-- Resource comparison(04-13-2026)
-- Peer district comparison — 2022-2023
-- ====================================================

-- Findings (2022-23):
--   lea              enrollment    district_fte    dist_student_teacher_ratio
--   Missoula H S:    3868          262.76          14.72
--   Helena H S:      2514          169.53          14.83
--   Flathead H S:    3101          196             15.82
--   Great Falls H S: 3095          195.38          15.84
--   Bozeman H S:     2631          161.56          16.28


select 
	leaid,
	district_name as lea,
	SUM(total_enrollment) as district_enrollment,
	SUM(teachers_FTE) as district_fte,
	ROUND(SUM(total_enrollment) / SUM(teachers_FTE), 2) as dist_student_teacher_ratio
from montana_schools.mt_schools_clean
where 
	school_year = '2022-2023'
	and cast(leaid as integer) IN (
		3004590,  -- Bozeman H S
		3015420,  -- Flathead H S
		3013050,  -- Great Falls H S
		3013830,  -- Helena H S
		3018540   -- Missoula H S
	)
	and total_enrollment > 100
group by leaid, lea
order by dist_student_teacher_ratio;

-- ============================================================
-- SECTION 3: KPS vs Peer Districts — Demographics comparison
-- ============================================================

--4/17/26: Compare demographic breakdown for peer districts for business question 1
-- created subquery to obtain derived table focusing only on peer districts
	-- used on '2022-2023' school_year based on this year being only overlapping year for resources and outcomes
-- collapsed final table to single row for each peer district
	-- used CASE statement to conditionally select for each nationality and to display pct enrollment (based on 100%) when true
-- will plan to create chart for finished project witht this table
-- Results: 
	-- Great Falls H S — most diverse: 9.7% AIAN, 6.1% Hispanic/Latino, only 74.3% White.   
	-- Helena H S — second most diverse: 2.5% AIAN, 7.1% Hispanic/Latino, 84.4% White                         
	-- Missoula H S — 85.2% White, 6% AIAN, 3.9% Hispanic/Latino                                        
	-- Bozeman H S — 86.2% White, 1.3% AIAN, 7% Hispanic/Latino                                                       
	-- Flathead H S (KPS) — least diverse: 90.1% White, lowest AIAN (1.0%) of group; Hispanic/Latino (4.3%)
select
	leaid,
	lea_name,
	MAX(
		case
			when peer_dists.race_ethnicity = 'Native Hawaiian or Other Pacific Islander' 
			then peer_dists.pct_enrollment
			else NULL
		end
		) as nhpi,
	MAX(
		case
			when peer_dists.race_ethnicity = 'Hispanic/Latino'
			then peer_dists.pct_enrollment 
			else NULL
		end
	) hisp_lat,
	MAX(
		case
			when peer_dists.race_ethnicity = 'American Indian or Alaska Native'
			then peer_dists.pct_enrollment 
			else NULL
		end
	) as aian,
	MAX(
		case
			when peer_dists.race_ethnicity = 'Asian'
			then peer_dists.pct_enrollment 
			else NULL
		end
	) as asian,
	MAX(
		case
			when peer_dists.race_ethnicity = 'White'
			then peer_dists.pct_enrollment 
			else NULL 
		end
	) as white,
	MAX(
		case
			when peer_dists.race_ethnicity = 'Black or African American'
			then peer_dists.pct_enrollment 
			else NULL
		end
	) as baa,
	MAX(
		case
			when peer_dists.race_ethnicity = 'Two or more races'
			then peer_dists.pct_enrollment 
			else NULL
		end
	) as tmr
from
	(select *
	from montana_schools.district_membership_clean
	where 	
		leaid in (
            3004590,  -- Bozeman H S
            3015420,  -- Flathead H S
            3013050,  -- Great Falls H S
            3013830,  -- Helena H S
            3018540   -- Missoula H S
		)
		and school_year = '2022-2023'
	) peer_dists
group by 
	leaid, 
	lea_name;

-- ============================================================
-- SECTION 4: Big picture for KPS vs peers in outcomes
-- ============================================================
-- Flathead has the worst overall graduation rate among peers, the worst rate for economically 
    --disadvantaged students, the largest gap between those two groups, and a declining trend.  