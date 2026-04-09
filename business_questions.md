# Business Questions
## Focus: Kalispell Public Schools (KPS) — District 5

KPS spans two NCES LEAIDs:
- `3015450` Kalispell Elem — several elementary and middle schools
- `3015420` Flathead H S — Flathead High School, Glacier High School

**Note:** Flathead H S serves students from several independent feeder districts
(Evergreen, West Valley, Cayuse Prairie, etc.) in addition to KPS elementary students.
Graduation rate analysis reflects the full Flathead H S cohort, which includes non-KPS students.

---

## Phase 1 — Current State (mt_schools_clean + graduation_rates_raw)

1. How does KPS compare to peer districts of similar enrollment size in resources and outcomes — analyzed separately for elementary (Kalispell Elem) and high school (Flathead H S) levels?
   - **Note (3/31/26):** High school outcomes available via graduation rates (graduation_rates_raw). Elementary outcomes not available — unable to obtain raw assessment scores or chronic absenteeism data from eddataexpress.ed.gov. Elementary comparison limited to resources only (enrollment, staffing, poverty).

2. Which school districts serve high-poverty communities?
3. How do graduation rates vary across Montana districts and what factors correlate with higher/lower rates?

---

## Future Consideration

- How are educational resources distributed across Montana by district?
- How do smaller school districts compare to larger school districts in resources and outcomes?
   - **Note (3/31/26):** Resources comparison fully available. Outcome comparisons limited — smaller districts have banded or suppressed graduation rate values, making precise numeric comparison unreliable.
- How are Montana districts changing over time in enrollment, demographic makeup, and staffing?
- Map district-level metrics (poverty rate, student-teacher ratio, graduation rate) to visualize regional patterns
    - Requires joining to county or district-level GIS/geometry data
    - Tools: QGIS, Tableau, or Python (geopandas)
