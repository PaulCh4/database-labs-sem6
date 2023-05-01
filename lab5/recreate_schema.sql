DROP SCHEMA if exists public CASCADE;
CREATE SCHEMA public;

create table university_log(
	id serial primary key,
	operation varchar(6) not null,
	new_id integer not null,
	old_id integer not null,
	old_name varchar(100) not null,
	old_date_founded date not null,
	log_time timestamp not null default now() 
);

create table group_log(
	id serial primary key,
	operation varchar(6) not null,
	new_id integer not null,
	old_id integer not null,
	old_name varchar(100) not null,
	old_university_id integer not null,
	log_time timestamp not null default now() 
);

create table student_log(
	id serial primary key,
	operation varchar(6) not null,
	new_id integer not null,
	old_id integer not null,
	old_name varchar(100) not null,
	old_group_id integer not null,
	log_time timestamp not null default now() 
);

create table report(
	report_time timestamp not null
);

create table university(
	id serial primary key,
	name varchar(100) unique not null,
	date_founded date not null
);

create table student_group(
	id serial primary key,
	name varchar(100) unique not null,
	university_id integer not null,
	foreign key (university_id) references university(id) on delete cascade
);

create table student(
	id serial primary key,
	name varchar(100) not null,
	group_id integer not null,
	foreign key (group_id) references student_group(id) on delete cascade
);



