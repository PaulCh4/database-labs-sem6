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





/*######################################################################*/
--Task4
select * from logging;

create table logging(
    id number primary key,
    action varchar2(10),
    logging_time timestamp,
    st_id_prev number,
    st_id number,
    st_name varchar2(100),
    st_group number
);

create sequence logging_sequence_id
start with 1;

create or replace trigger students_logging
after insert or update or delete on students
for each row
declare
    cur_action varchar2(10);
begin
    if inserting then
        cur_action := 'ins';
        insert into logging (id, action, logging_time, st_id_prev, st_id, st_name, st_group)
            values (logging_sequence_id.nextval, cur_action, current_timestamp, null, :new.id, :new.name, :new.group_id);
    elsif updating then
        cur_action := 'upd';
        insert into logging (id, action, logging_time, st_id_prev, st_id, st_name, st_group)
            values (logging_sequence_id.nextval, cur_action, current_timestamp, :old.id, :new.id, :old.name, :old.group_id);
    elsif deleting then
        cur_action := 'del';
        insert into logging (id, action, logging_time, st_id_prev, st_id, st_name, st_group)
            values (logging_sequence_id.nextval, cur_action, current_timestamp, :old.id, null, :old.name, :old.group_id);
  end if;
end;






/*######################################################################*/
--Task5
create or replace procedure restore_information(t timestamp) is
begin
    for i in (select action, st_id_prev, st_id, st_name, st_group
              from logging where logging_time >= t order by id desc) loop
        if i.action = 'ins' then
            delete from students where id = i.st_id;
        elsif i.action = 'upd' then
            update students set id = i.st_id_prev, name = i.st_name, group_id = i.st_group where id = i.st_id;
        elsif i.action = 'del' then
            insert into students (id, name, group_id) values (i.st_id_prev, i.st_name, i.st_group);
        end if;
    end loop;
end;
select *
from logging;
begin
    restore_information(to_timestamp('20.02.2023 14:46:20'));
    --restore_information(to_timestamp(current_timestamp - 10));
end;