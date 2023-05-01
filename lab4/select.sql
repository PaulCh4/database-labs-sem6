drop function if exists parse_select;
drop function if exists make_select_query;

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


-- NESTED
select name from student
where id > 2 and name in (
	select name from student
	where id % 2 = 0
);

select parse_select('{
	"operation": "select",
	"fields":["name"],
	"table": "student",
    "filters": [
        {
            "type": "primitive",
            "condition": "id > 2",
            "logical_operation": "and"
        },
        {
            "type": "nested",
            "condition": "name in",
            "query": {
                "operation": "select",
                "fields": ["name"],
                "table": "student",
                "filters": [
                    {
                        "type": "primitive",
                        "condition": "id % 2 = 0"
                    }
                ]
            }
        }
    ]
}');


