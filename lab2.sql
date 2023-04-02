--Task1
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
--insert into students(id, name, group_id) values(64, 'Paul', 2); 
--insert into groups(id, name, c_val) values(1,'A', 0); 
--select * from students;
--select * from groups;


--2) auto-increment
create sequence student_id
start with 1;
--drop sequence student_id

create or replace trigger student_id_generating
before insert on students
for each row
begin
    :new.id := student_id.nextval;
end;



create sequence group_id
start with 1;
--drop sequence group_id

create or replace trigger group_id_generating
before insert on groups
for each row
begin
    :new.id := group_id.nextval;
end;
--insert into students(name, group_id) values('dwad', 1); insert into students(name, group_id) values('dwad', 2); 
--insert into groups(id, name, c_val) values(1,'A', 0); 
--drop table students;
--drop table groups;
--select * from students;
--select * from groups;



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
--insert into groups(id, name, c_val) values(1,'A', 0); 
--select * from students;
--select * from groups;





/*######################################################################*/
--Task3
create or replace trigger foreign_key
before delete on groups
for each row
begin
    delete from students where group_id = :old.id;
end;

--delete groups where id='1';

--insert into students(name, group_id) values('dwad', 1); insert into students(name, group_id) values('dwad', 2); 
--insert into groups(id, name, c_val) values(1,'A', 0); 
--drop table students;
--drop table groups;

--select * from students;
--select * from groups;




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
--delete groups where name='A';

--insert into students(name, group_id) values('dwad', 1); 
--insert into students(name, group_id) values('Lary', 2); 
--delete students where name='Lary';
--insert into groups(name, c_val) values('A', 2); 
--drop table students;
--drop table groups;

--select * from students;
--select * from groups;
--select * from logging;



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

begin 
    restore_information(to_timestamp('10-MAR-23 09:25:55'));
end;

--insert into students(name, group_id) values('PPPPPP', 2);
--delete students where name='PPPPPP';
--select * from logging;
--select * from students;


  
/*######################################################################*/
--Task6
create or replace procedure upd(in_id number, cnt number) is
    pragma autonomous_transaction;
begin
    update groups set c_val = c_val + cnt where id = in_id;
    commit;
end;

create or replace trigger amount_updating
after delete or insert or update on students
for each row
begin
    if inserting then
        upd(:new.group_id, 1);
    elsif deleting then
        upd(:old.group_id, -1);
    elsif updating then
        upd(:new.group_id, 1);
        upd(:old.group_id, -1);
    end if;
end;

--insert into groups(name, c_val) values('A', 0); 
--insert into groups(name, c_val) values('B', 0); 
--insert into students(name, group_id) values('1PPPPPP', 1);
--insert into students(name, group_id) values('2PPPPPP', 3);
--insert into students(name, group_id) values('3PPPPPP', 3);
--insert into students(name, group_id) values('6PPPPPP', 2);
--delete students where name='2PPPPPP';

--select * from groups;
--select * from students;

--select * from logging;



/*########################################################################*/
drop trigger student_id_unique;
drop trigger group_id_unique;

drop sequence student_id;
drop trigger student_id_generating;

drop sequence group_id;
drop trigger group_id_generating;

drop trigger group_name_unique;


drop trigger foreign_key;


drop table logging;
drop sequence logging_sequence_id;
drop trigger students_logging;


drop procedure restore_information;


drop procedure upd;
drop trigger amount_updating;
/*###############################################################*/

insert into groups(name, c_val) values('A', 0); 
insert into groups(name, c_val) values('B', 0); 
insert into groups(id, name, c_val) values('A', 0); 
insert into groups(id, name, c_val) values('B', 0); 
insert into students(name, group_id) values('4stud', 1);
insert into students(name, group_id) values('2PPPPPP', 2);
insert into students(name, group_id) values('3PPPPPP', 1);
insert into students(name, group_id) values('6PPPPPP', 2);
delete students where name='6PPPPPP';

select * from groups;

insert into students(id, name) values(1, 'dwad'); 
insert into students(id, name) values(62, 'A'); 
insert into students(id, name) values(2, 'dwad'); 
insert into students(id, name) values(3, 'dwaqewd'); 
insert into students(id, name) values(4, 'dwad');

insert into students(name, group_id) values('PPPPPP', 2);
delete students where name='PPPPPP';
 
select * from students;
select * from logging;
--restore_information(to_timestamp(current_timestamp - 10));