drop function if exists read_file;
drop function if exists parse_drop;
drop function if exists make_drop_query;

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

create or replace function make_drop_query(json_data json)
returns text
language plpgsql
as $$
declare
	table_name text;
	
	query_text text;
begin
	table_name = json_data->>'table';
	
	query_text := format('drop table if exists %s cascade', table_name);
	
	return query_text;
end;
$$;

create or replace function parse_drop(file_abs_path text)
returns void
as $$
declare
	json_data text;
	drop_item json;
	query text;
begin
	select read_file(file_abs_path) into json_data;
	
	for drop_item in select json_array_elements(json_data::json) loop
		query = make_drop_query(drop_item);
		raise notice '%', query;
		execute query;
	end loop;
end;
$$;

select parse_drop('/media/data/programming/6sem/db/lab4/drop_tables.json');



