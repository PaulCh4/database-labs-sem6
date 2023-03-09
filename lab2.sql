--Task1
create database bsuir_labs;
use bsuir_labs;

create table STUDENTS(
    id number,
    name varchar2(50),
    group_id number
);

create table GROUPS(
    id number,
    name varchar2(50),
    c_val number
);

drop table students; 
drop table groups;
insert into students(id, name) values(1, 'dwad'); 
insert into students(id, name) values(2, 'dwqead'); 
insert into students(id, name) values(2, 'dwad'); 
insert into students(id, name) values(3, 'dwaqewd'); 
insert into students(id, name) values(4, 'dwad'); 







/*######################################################################*/
--Task2
--1) id unique
create or replace trigger student_id_unique
before insert on students
for each row
declare
    cnt number;
begin
    select count(*) into cnt from students where id = :new.id;
    if cnt > 0 then
        raise_application_error(-20101, 'ERROR id must be unique');
    end if;
end;



create or replace trigger group_id_unique
before insert on groups
for each row
declare
    cnt number;
begin
    select count(*) into cnt from groups where id = :new.id;
    if cnt > 0 then
        raise_application_error(-20101, 'ERROR id must be unique');
    end if;
end;



--2) auto-increment
create sequence student_id
start with 1;

create or replace trigger student_id_generating
before insert on students
for each row
begin
    :new.id := student_id.nextval;
end;



create sequence group_id
start with 1;

create or replace trigger group_id_generating
before insert on groups
for each row
begin
    :new.id := group_id.nextval;
end;



--3)group name
create or replace trigger group_name_unique
before insert on groups
for each row
declare
    cnt number;
begin
    select count(*) into cnt from groups where name = :new.name;
    if cnt > 0 then
        raise_application_error(-20101, 'ERROR name must be unique');
    end if;
end;






/*######################################################################*/
--Task3
create or replace trigger foreign_key
before delete on groups
for each row
begin
    delete from students where group_id = :old.id;
end;




