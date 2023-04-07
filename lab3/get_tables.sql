--CREATE TABLE temp_table (symbol VARCHAR2(1), col_name VARCHAR2(30), col_type VARCHAR2(30), table_name VARCHAR2(30));
--DELETE temp_table WHERE 0 = 0;
--DROP TABLE temp_table;
--SELECT * FROM temp_table;
--
--SELECT * FROM students;

SELECT * FROM temp_table; 

--INSERT INTO foreign_keys_table (table_name, r_table_name) VALUES ('THIRD_TABLE', 'FORTH_TABLE');

--SELECT DISTINCT table_name, r_table_name
    --FROM foreign_keys_table;

SELECT * FROM order_table;

DECLARE
    CURSOR c_tables IS
        SELECT table_name, r_table_name
        FROM foreign_keys_table;
    table_order SYS_REFCURSOR;
    table_name VARCHAR2(30);
BEGIN
    OPEN table_order FOR
        WITH ordered_tables AS (
            SELECT table_name, r_table_name,
                ROW_NUMBER() OVER (ORDER BY LEVEL) AS "order"
            FROM foreign_keys_table
            CONNECT BY NOCYCLE PRIOR r_table_name = table_name
            START WITH table_name NOT IN (SELECT r_table_name FROM foreign_keys_table)
        )
        SELECT table_name FROM ordered_tables ORDER BY "order";
    LOOP
        FETCH table_order INTO table_name;
        EXIT WHEN table_order%NOTFOUND;
        INSERT INTO order_table (table_name) VALUES (table_name);
        DBMS_OUTPUT.PUT_LINE(table_name);
    END LOOP;
    CLOSE table_order;
    
    FOR rec IN (
        SELECT DISTINCT column_value AS table_name FROM (
            SELECT table_name AS column_value FROM foreign_keys_table
            UNION ALL
            SELECT r_table_name AS column_value FROM foreign_keys_table
        )
        WHERE column_value NOT IN (
            SELECT table_name FROM (
                SELECT table_name, r_table_name,
                    ROW_NUMBER() OVER (ORDER BY LEVEL) AS "order"
                FROM foreign_keys_table
                CONNECT BY NOCYCLE PRIOR r_table_name = table_name
                START WITH table_name NOT IN (SELECT r_table_name FROM foreign_keys_table)
            )
        )
    ) LOOP
        INSERT INTO order_table (table_name) VALUES (table_name);
        DBMS_OUTPUT.PUT_LINE(rec.table_name);
    END LOOP;
END;
/
