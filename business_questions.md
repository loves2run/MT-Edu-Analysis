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
2. How are educational resources distributed across Montana by district?
3. How do smaller school districts compare to larger school districts in resources and outcomes?
5. Which school districts serve high-poverty communities?
6. How do graduation rates vary across Montana districts and what factors correlate with higher/lower rates?

## Phase 2 — Trends Over Time (requires district tables)

4. How are Montana districts changing over time in enrollment, demographic makeup, and staffing?

---

## Future Consideration — Geographic Distribution

- Map district-level metrics (poverty rate, student-teacher ratio, graduation rate) to visualize regional patterns
- Requires joining to county or district-level GIS/geometry data
- Tools: QGIS, Tableau, or Python (geopandas)
