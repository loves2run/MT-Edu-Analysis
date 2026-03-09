# Graduation Rates Cleaning Checklist

Source table: `montana_schools.graduation_rates_raw` (7,486 rows)
Target: a cleaned, analysis-ready table (name TBD)

---

## Step 1 — Understand the full column set

Look at all columns and decide which are needed. The raw table has 18 columns — many may be empty or irrelevant.

**Why:** No point cleaning or carrying columns you'll never use.

- [ ] Inspect the raw table to see all columns and sample values
- [ ] Identify any columns that appear empty, constant, or clearly irrelevant
- [ ] Document which columns to keep and why

---

## Step 2 — Investigate the 2020-21 row count discrepancy

District-level row counts are consistent across years (158/161/162), but the 2020-21 total row count is 37% higher than the other years. Investigate whether that discrepancy lives at the school level.

**Why:** Before cleaning, confirm whether 2020-21 school-level data is trustworthy or structurally different.

- [ ] Separate school-level and district-level rows and compare counts by year
- [ ] Look for structural differences in 2020-21 that might explain the extra rows
- [ ] Decide whether 2020-21 school-level data is safe to include

---

## Step 3 — Decide on school-level vs district-level

Based on step 2 findings, decide whether to keep both levels together or handle them separately.

**Why:** Mixing levels in one table creates aggregation errors. A flag or split prevents accidental double-counting.

- [ ] Choose an approach: single table with a level flag, or two separate tables
- [ ] Document your decision and rationale

---

## Step 4 — Handle the value column

The graduation rate column contains a mix of formats that need to be converted into something analytically useful.

Known value types:
- Exact numeric strings: `"72.4"`
- Banded ranges of varying widths: `"GE50LT60"`, `"GE80"`, etc.
- `"S"` — suppressed (small population)
- `"."` — 2020-21 no-data marker (school-level only; zero district-level rows affected)

**Why:** You can't do math or sort meaningfully on strings like `GE50LT60`.

- [ ] Explore all distinct values in the value column to understand the full range of formats
- [ ] Decide how to represent banded values numerically (midpoint, lower bound, or NULL + flag)
- [ ] Plan a conversion approach that handles all value types in one place

---

## Step 5 — Handle suppressed values (S)

Decide whether `S` becomes NULL or gets a separate flag.

**Why:** Suppressed data isn't missing data — it signals a small population. Treating it as NULL loses that distinction and can mislead analysis.

- [ ] Check how common suppressed values are at the district level
- [ ] Decide whether the distinction between suppressed and missing is important enough to preserve explicitly

---

## Step 6 — Identify and keep only needed columns

Drop or ignore columns that are empty, redundant, or not useful for the planned analysis.

**Why:** Keeps the clean table lean and readable.

- [ ] Finalize the column list before writing the CREATE TABLE statement
- [ ] Make sure each column kept ties back to at least one business question

---

## Step 7 — Add a county column

The graduation rate data has `leaid` but no county. County is needed for regional comparisons.

**Why:** Several business questions require grouping districts by county or comparing KPS to peer districts within a region.

**Challenge:** No direct district-to-county mapping exists in the current tables. Think through how you'd bridge from `leaid` to county using what you already have.

- [ ] Identify a join path from graduation rate districts to county
- [ ] Check how complete that join would be — are there districts that won't match?
- [ ] Handle any gaps

---

## Step 8 — Verify row counts and joins

After cleaning, confirm the cleaned table is well-formed and connects properly to your other data.

**Why:** A clean table that doesn't join properly to your other data is useless.

- [ ] Verify row counts by year and level match expectations
- [ ] Test joins to `mt_schools_clean` at both district and school level — check for unmatched rows
- [ ] Spot-check KPS to confirm it appears correctly
