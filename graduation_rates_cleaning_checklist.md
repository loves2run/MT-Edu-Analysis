# Graduation Rates Cleaning Checklist

Source table: `montana_schools.graduation_rates_raw` (7,486 rows)
Target: a cleaned, analysis-ready table (name TBD)

---

## Step 1 — Understand the full column set

Look at all columns and decide which are needed. The raw table has 18 columns — many may be empty or irrelevant.

**Why:** No point cleaning or carrying columns you'll never use.

- [ ] Run `SELECT * FROM graduation_rates_raw LIMIT 5` to see all column names and sample values
- [ ] Run `SELECT column_name FROM information_schema.columns WHERE table_name = 'graduation_rates_raw'` for the full list
- [ ] For suspect columns, check if they are entirely NULL or a single constant value
- [ ] Document which columns to keep and why

---

## Step 2 — Investigate the 2020-21 row count discrepancy

Filter to school-level rows only and compare counts by year. District-level is consistent (158/161/162), but school-level may have real differences worth understanding.

**Why:** Before cleaning, confirm whether 2020-21 school-level data is trustworthy or structurally different.

- [ ] Filter where `school != ''` (or however school-level is identified) and count by year
- [ ] Check if 2020-21 school-level rows have different subgroup breakdowns or extra category rows
- [ ] Decide: is 2020-21 school-level data safe to include alongside 2021-22 and 2022-23?

---

## Step 3 — Decide on school-level vs district-level

Based on step 2 findings, decide whether to keep both levels in one table with a flag column, or split into two tables.

**Why:** Mixing levels in one table creates aggregation errors. A flag or split prevents accidental double-counting.

- [ ] If keeping together: add a `level` column (`'district'` / `'school'`) populated from the school identifier column
- [ ] If splitting: create `graduation_rates_district` and `graduation_rates_school` separately
- [ ] Document decision and rationale

---

## Step 4 — Handle the value column

The graduation rate column contains a mix of formats that need to be converted into something analytically useful.

Known value types:
- Exact numeric strings: `"72.4"`
- Banded ranges of varying widths: `"GE50LT60"`, `"GE80"`, etc.
- `"S"` — suppressed (small population)
- `"."` — 2020-21 no-data marker (school-level only; zero district-level rows affected)

**Why:** You can't do math or sort meaningfully on strings like `GE50LT60`.

- [ ] Run `SELECT DISTINCT value FROM graduation_rates_raw` to see all formats
- [ ] Decide on approach for banded values: midpoint, lower bound, or NULL + flag
- [ ] Write a CASE expression to parse `value` into a numeric column (e.g. `graduation_rate`)
- [ ] Consider a `value_type` flag column: `'exact'`, `'banded'`, `'suppressed'`, `'missing'`

---

## Step 5 — Handle suppressed values (S)

Decide whether `S` becomes NULL or gets a separate flag.

**Why:** Suppressed data isn't missing data — it signals a small population. Treating it as NULL loses that distinction and can mislead analysis.

- [ ] Decide: NULL with a `is_suppressed BOOLEAN` column, or a `value_type` text flag (can combine with step 4)
- [ ] Count how many district-level rows are suppressed — if rare, NULL may be fine; if common, the flag matters more

---

## Step 6 — Identify and keep only needed columns

Drop or ignore columns that are empty, redundant, or not useful for the planned analysis.

**Why:** Keeps the clean table lean and readable.

- [ ] Confirm final column list before writing the CREATE TABLE statement
- [ ] Cross-reference with business questions — does each column support at least one question?

---

## Step 7 — Add a county column

The graduation rate data has `leaid` but no county. County is needed for regional comparisons.

**Why:** Several business questions require grouping districts by county or comparing KPS to peer districts within a region.

**Challenge:** No direct district-to-county mapping exists in current tables. Options:
- Join `graduation_rates_raw` → `mt_schools_clean` on `leaid` → `leaid`, then pull `county` from there
- Join on district name (fragile — spelling mismatches likely)
- Manually build a small `district_county` lookup table for the ~160 districts

- [ ] Check how many distinct `leaid` values in `graduation_rates_raw` match `leaid` in `mt_schools_clean`
- [ ] Determine join success rate before committing to this approach
- [ ] Handle any unmatched districts (manual lookup or NULL with a note)

---

## Step 8 — Verify row counts and joins

After cleaning, confirm the cleaned table joins correctly to `mt_schools_clean` at both school and district level.

**Why:** A clean table that doesn't join properly to your other data is useless.

- [ ] Count rows in cleaned table by year and level — should match expectations from step 2
- [ ] Test district-level join: `graduation_rates_clean JOIN mt_schools_clean ON leaid` — count matched vs unmatched
- [ ] Test school-level join: `ON nces_sch_id = ncessch` — count matched vs unmatched
- [ ] Spot-check KPS: confirm Flathead H S and Kalispell Elem appear correctly
