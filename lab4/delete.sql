drop function if exists read_file;
drop function if exists make_delete_query;
drop function if exists make_select_query;
drop function if exists parse_delete;

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

create or replace function make_delete_query(json_data json)
returns text
as $$
declare
	fields text[];
	fields_str text;
	
	table_name text;
	
	filters json;
	filter_item json;
	FILTER_PRIMITIVE_TYPE constant text := 'primitive';
	FILTER_NESTED_TYPE constant text := 'nested';
	
	query_text text;
begin
	fields = array(select json_array_elements_text(json_data->'fields'));
	fields_str = array_to_string(fields, ', ');
	
	table_name = json_data->>'table';
	
	query_text := format('delete from %s ', table_name);

	filters = json_data->'filters';
	if filters is not NULL then
		query_text = query_text || ' where ';
		
		for filter_item in select json_array_elements(filters) loop
			query_text = query_text || (filter_item->>'condition')::text;
			
			if filter_item->>'type' = FILTER_NESTED_TYPE then
				query_text = query_text || ' (' || make_select_query(filter_item->'query') || ') ';
			end if;
			
			if filter_item->>'logical_operation' is not NULL then
				query_text = query_text || ' ' || (filter_item->>'logical_operation')::text || ' ';
			end if;
		end loop;
	end if;
	
	return query_text;
end;
$$;


