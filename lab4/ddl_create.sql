drop function if exists read_file;
drop function if exists parse_create;

create or replace function read_file(file_path text)
returns text
as $$
declare
	content text;
	file_line text;
begin
	file_path := quote_literal(file_path);
	
	drop table if exists temp_table;
	create table temp_table(t text);
	execute 'copy temp_table from ' || file_path;
	
	content = '';
	
	for file_line in select t from temp_table loop
		content = content || file_line;
	end loop;
	
	drop table if exists temp_table;

	return content;
end;
$$;




create or replace function make_trigger_query(pk_field_name text, table_name text)
returns text
as $$
declare
	trigger_text text;
begin
	trigger_text = format('create or replace function pk_trigger_function()
	returns trigger
	as $qwe$
	declare 
		max_id_in_table int;
		provided_id_res bool := false;
	begin
		if NEW.%1$s is not NULL then
			select into provided_id_res not exists(
				select * from student where id = NEW.%1$s
			);

			if not provided_id_res then
				raise exception ''Integrity check: FAIL (pk %% already exists)'', NEW.%1$s;
			end if;
		else
			execute format(''select max(id) from %%I'', TG_TABLE_NAME) into max_id_in_table;

			if max_id_in_table is NULL then
				NEW.%1$s = 1;
			else
				NEW.%1$s = max_id_in_table + 1;
			end if;
		end if;

		raise notice ''Table: "%%" Generated pk: %%'', TG_TABLE_NAME, NEW.%1$s;

		return NEW;
	end;
	$qwe$; 

	create trigger pk_trigger
	before insert on %2$s
	for each row execute procedure pk_trigger_function(); ', pk_field_name, table_name);

	return trigger_text;
end;
$$;



create or replace function make_create_query(json_data json)
returns text
language plpgsql
as $$
declare
	fields json;
	field_item json;
	
	table_name text;
	pk_field_name text;
	
	query_text text;
	
	trigger_text text;
begin
	table_name = json_data->>'table';
	
	query_text := format('create table %s (', table_name);
	
	fields = json_data->'fields';
	for field_item in select json_array_elements(fields) loop
		query_text = query_text || 
				(field_item->>'name')::text || ' ' 
				|| (field_item->>'type')::text || ', ';
		
		if field_item->>'foreign_key' is not NULL then
			query_text = query_text || 
				format(' foreign key (%s)', field_item->>'name') || (field_item->>'foreign_key')::text || ', ';
		end if;
		
		if field_item->>'is_pk' = 'true' then
			pk_field_name = field_item->>'name';
		end if;
	end loop;
	
	query_text = substring(query_text, 1, length(query_text) - 2);
	query_text = query_text || '); ';
	
end;
$$;



select parse_create('/media/data/programming/6sem/db/lab4/create_tables.json');



