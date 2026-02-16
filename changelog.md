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