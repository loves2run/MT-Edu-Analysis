-- ============================================================
-- SECTION 1: KPS vs Peer Districts — Graduation Rate Analysis
-- ============================================================

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
