select * from university;

select * from student;

select * from student_group;

update university
set name = concat('updated ', name)
where id > 3 and name in (
	select name from university
	where lower(name) like 'json%'
);

delete from university
where id > 3 and name in (
	select name from university
	where lower(name) like 'json%'
);

select * from json_table2;
insert into json_table2(val) values (1), (123), (666);
