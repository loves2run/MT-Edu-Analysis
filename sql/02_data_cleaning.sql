-- working query: school directory + membership + staff joined
-- joins 3 tables to get school info, enrollment, and teachers for Montana
-- TODO: add more columns, join, lunch, handle NULLs, turn into CREATE TABLE

select d.sch_name, 
    m.student_count, 
    s.teachers,
    ROUND(m.student_count / s.teachers, 1) as sudent_teach_ratio
from school_directory d
join school_membership m
    on d.ncessch = m.ncessch 
    and d.school_year = m.school_year 
join school_staff s
    on d.ncessch  = s.ncessch 
    and d.school_year = s.school_year 
where d.st = 'MT'
    and m.total_indicator = 'Education Unit Total'
    and s.teachers > 0
limit 10;