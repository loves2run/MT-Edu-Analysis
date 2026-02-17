-- working query: school directory + membership + staff joined
-- joins 3 tables to get school info, enrollment, and teachers for Montana
-- TODO: add more columns, join, lunch, handle NULLs, turn into CREATE TABLE

create table mt_schools_clean AS
select d.ncessch, d.leaid, d.sch_name, d.lea_name,
    d.lcity, d.lzip, d.level, d.gslo, d.gshi, 
    d.sch_type_text, d.charter_text, d.sy_status_text,
    d.school_year, m.student_count, s.teachers,
    ROUND(m.student_count / s.teachers, 1) as student_teach_ratio,
    l.free_reduced_lunch,
  	ROUND(100.0 * l.free_reduced_lunch / m.student_count, 1) as poverty_pct
from school_directory d
join school_membership m
    on d.ncessch = m.ncessch 
    and d.school_year = m.school_year 
join school_staff s
    on d.ncessch  = s.ncessch 
    and d.school_year = s.school_year 
left join (
select ncessch, school_year,
    SUM(student_count) as free_reduced_lunch 
from montana_schools.school_lunch
where lunch_program in ('Free lunch qualified', 'Reduced-price lunch qualified')
group by ncessch, school_year
) l
    on d.ncessch = l.ncessch
    and d.school_year = l.school_year
where d.st = 'MT'
    and m.total_indicator = 'Education Unit Total'
    and s.teachers > 0;