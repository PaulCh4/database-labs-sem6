drop function if exists parse_select;
drop function if exists make_select_query;


create or replace function parse_select(json_data text)
returns refcursor
as $$
declare
	res_cursor refcursor;
	query text;
	rec record;
begin
	query = make_select_query(json_data::json);
	raise notice '%', query;
	open res_cursor for execute query;
	
	loop
		fetch res_cursor into rec;
		exit when not found;
		
		raise notice '%', rec;
	end loop;
	
	close res_cursor;
	
	open res_cursor for execute query;
	
	return res_cursor;
end;
$$;

--
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


