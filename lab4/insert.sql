drop function if exists read_file;
drop function if exists parse_insert;

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

create or replace function make_insert_query(json_data json)
returns text
as $$
declare
	fields text[];
	fields_str text;
	
	values_str text;
	
	table_name text;
	
	query_text text;
begin
	fields = array(select json_array_elements_text(json_data->'fields'));
	fields_str = array_to_string(fields, ', ');
	
	table_name = json_data->>'table';
	
	values_str = (json_data->'values')::text;
	values_str = substring(values_str, 2, length(values_str) - 2);
	values_str = replace(values_str, '"', '''');
	
	query_text := format('insert into %s(%s) values(%s)', 
					table_name, fields_str, values_str);

	return query_text;
end;
$$;

select parse_insert('/media/data/programming/6sem/db/lab4/insert_data.json');


