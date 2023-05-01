DROP SCHEMA if exists public CASCADE;
CREATE SCHEMA public;

create table university(
	id serial primary key,
	name varchar(100) not null
);

create table student_group(
	id serial primary key,
	name varchar(100) not null,
	university_id integer not null,
	foreign key (university_id) references university(id) on delete cascade
);

create table student(
	id serial primary key,
	name varchar(100) not null,
	group_id integer not null,
	foreign key (group_id) references student_group(id) on delete cascade
);

insert into university(name) values ('bsuir'), ('mglu');

insert into student_group(name, university_id) values ('953504', 1), ('953505', 2);

insert into student(name, group_id) values('student1', 1);
insert into student(name, group_id) values('student2', 2);
insert into student(name, group_id) values('student3', 1);
insert into student(name, group_id) values('student4', 2);

