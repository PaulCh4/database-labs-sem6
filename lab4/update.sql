drop function if exists read_file;
drop function if exists make_update_query;
drop function if exists make_select_query;
drop function if exists parse_update;

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

create or replace function make_select_query(json_data json)
returns text
as $$
declare
	fields text[];
	fields_str text;
	
	join_item json;
	
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
	
	query_text := format('select %s from %s', 
					fields_str, table_name);
			
	for join_item in select json_array_elements(json_data->'join') loop
		query_text = query_text || ' join ' || (join_item->>'table')::text;
		query_text = query_text || ' on ' || (join_item->>'on')::text;
	end loop;
	
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

create or replace function make_update_query(json_data json)
returns text
as $$
declare
	fields text[];
	fields_str text;
	
	table_name text;
	set_text text;
	
	filters json;
	filter_item json;
	FILTER_PRIMITIVE_TYPE constant text := 'primitive';
	FILTER_NESTED_TYPE constant text := 'nested';
	
	query_text text;
begin
	fields = array(select json_array_elements_text(json_data->'fields'));
	fields_str = array_to_string(fields, ', ');
	
	table_name = json_data->>'table';
	set_text = json_data->>'set';
	
	query_text := format('update %s set %s ', 
					table_name, set_text);

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

create or replace function parse_update(file_abs_path text)
returns void
as $$
declare
	json_data text;
	update_item json;
	query text;
begin
	select read_file(file_abs_path) into json_data;
	
	for update_item in select json_array_elements(json_data::json) loop
		query = make_update_query(update_item);
		raise notice '%', query;
		execute query;
	end loop;
end;
$$;

select parse_update('/media/data/programming/6sem/db/lab4/update_data.json');



