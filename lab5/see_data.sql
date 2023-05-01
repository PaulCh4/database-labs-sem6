select * from university;

select * from student;

select * from student_group;

select * from university_log;

select * from report order by report_time desc;


select student.name, student_group.name as group_name, university.name as university
from student
join student_group
on student.group_id = student_group.id
join university
on student_group.university_id = university.id;

-- data to log
insert into university(name, date_founded) values('uni to log', '1999-11-19');
insert into university(name, date_founded) values('another uni to log', '2001-08-11');


