CREATE OR REPLACE PROCEDURE compare_table_structure (
  schema1 VARCHAR2,
  table1 VARCHAR2,
  schema2 VARCHAR2,
  table2 VARCHAR2
)
AS
  col_name VARCHAR2(30);
  col_type VARCHAR2(30);
  match_count NUMBER;
  symbol VARCHAR2(1);
  out_cur SYS_REFCURSOR;
BEGIN
  SELECT COUNT(*) INTO match_count
  FROM all_tables
  WHERE (owner = schema1 AND table_name = table1)
    OR (owner = schema2 AND table_name = table2);
    
  IF match_count < 2 THEN
    RAISE_APPLICATION_ERROR(-20001, 'One or both tables do not exist in the specified schemas');
  END IF;

  OPEN out_cur FOR
    SELECT '+' AS symbol, column_name AS col_name, data_type AS col_type
    FROM all_tab_cols
    WHERE owner = schema1 AND table_name = table1
    MINUS
    SELECT '+' AS symbol, column_name, data_type
    FROM all_tab_cols
    WHERE owner = schema2 AND table_name = table2
    UNION ALL
    SELECT '-' AS symbol, column_name, data_type
    FROM all_tab_cols
    WHERE owner = schema2 AND table_name = table2
    MINUS
    SELECT '-' AS symbol, column_name, data_type
    FROM all_tab_cols
    WHERE owner = schema1 AND table_name = table1;
    
  LOOP
    FETCH out_cur INTO symbol, col_name, col_type;
    EXIT WHEN out_cur%NOTFOUND;
    INSERT INTO temp_table VALUES (symbol, col_name, col_type, table1);
  END LOOP;
END;
/

CREATE OR REPLACE PROCEDURE compare_all_tables (
    schema1 VARCHAR2,
    schema2 VARCHAR2
)
AS
    table_name1 VARCHAR2(30);
    table_name2 VARCHAR2(30);
    table_cur1 SYS_REFCURSOR;
    table_cur2 SYS_REFCURSOR;
BEGIN
    DELETE temp_table WHERE 0 = 0;
    
    -- Initialize the cursor with all table names in the schema ordered by name
    OPEN table_cur1 FOR
        SELECT table_name
        FROM all_tables
        WHERE owner = schema1
        ORDER BY table_name;
        
    OPEN table_cur2 FOR
        SELECT table_name
        FROM all_tables
        WHERE owner = schema2
        ORDER BY table_name;
    
    FETCH table_cur1 INTO table_name1;
    FETCH table_cur2 INTO table_name2;
        
    -- Loop indefinitely while fetching table names from the cursor
    LOOP
        EXIT WHEN table_cur1%NOTFOUND OR table_cur2%NOTFOUND;
        
        DBMS_OUTPUT.put_line('compare ' || table_name1 || ' and ' || table_name2);
        
        IF table_name1 = 'TEMP_TABLE' OR table_name1 = 'FOREIGN_KEYS_TABLE' THEN
            FETCH table_cur1 INTO table_name1;
            CONTINUE;
        END IF;
        
        IF table_name2 = 'TEMP_TABLE' OR table_name2 = 'FOREIGN_KEYS_TABLE' THEN
            FETCH table_cur2 INTO table_name2;
            CONTINUE;
        END IF;
        
        IF table_name1 = table_name2 THEN
            compare_table_structure(schema1, table_name1, schema2, table_name2);
            
            FETCH table_cur1 INTO table_name1;
            FETCH table_cur2 INTO table_name2;
        ELSIF table_name1 > table_name2 THEN
            INSERT INTO temp_table VALUES ('-', '~', '~', table_name2);
            DBMS_OUTPUT.put_line('Unique ' || table_name2);
            FETCH table_cur2 INTO table_name2;
        ELSIF table_name2 > table_name1 THEN
            INSERT INTO temp_table VALUES ('+', '~', '~', table_name1);
            DBMS_OUTPUT.put_line('Unique ' || table_name1);
            FETCH table_cur1 INTO table_name1;
        END IF;
        
        -- Process the table name here
    END LOOP;
    
    LOOP
        EXIT WHEN table_cur1%NOTFOUND;
        IF table_name1 = 'TEMP_TABLE' OR table_name1 = 'FOREIGN_KEYS_TABLE' THEN
            FETCH table_cur1 INTO table_name1;
            CONTINUE;
        END IF;
        INSERT INTO temp_table VALUES ('+', '~', '~', table_name1);
        DBMS_OUTPUT.put_line('Unique ' || table_name1);
        FETCH table_cur1 INTO table_name1;
    END LOOP;
    
    LOOP
        EXIT WHEN table_cur2%NOTFOUND;
        IF table_name2 = 'TEMP_TABLE' OR table_name2 = 'FOREIGN_KEYS_TABLE' THEN
            FETCH table_cur2 INTO table_name2;
            CONTINUE;
        END IF;
        INSERT INTO temp_table VALUES ('-', '~', '~', table_name2);
        DBMS_OUTPUT.put_line('Unique ' || table_name2);
        FETCH table_cur2 INTO table_name2;
    END LOOP;
    
    -- Close the cursor when done
    CLOSE table_cur1;
    CLOSE table_cur2;
END;
/

CREATE OR REPLACE PROCEDURE get_foreign_keys(owner_name IN VARCHAR2) IS
BEGIN
  FOR rec IN (
    SELECT a.table_name, a.column_name, a.constraint_name, c_pk.table_name r_table_name
    FROM all_cons_columns a
    JOIN all_constraints c ON a.owner = c.owner
                        AND a.constraint_name = c.constraint_name
    JOIN all_constraints c_pk ON c.r_owner = c_pk.owner
                           AND c.r_constraint_name = c_pk.constraint_name
    WHERE c.constraint_type = 'R' AND c.owner = owner_name
  ) LOOP
    INSERT INTO foreign_keys_table (
      table_name,
      column_name,
      constraint_name,
      r_table_name,
      owner
    ) VALUES (
      rec.table_name,
      rec.column_name,
      rec.constraint_name,
      rec.r_table_name,
      owner_name
    );
  END LOOP;
END;
/

CREATE OR REPLACE PROCEDURE order_tables (a NUMBER)
IS
    CURSOR c_tables IS
        SELECT table_name, r_table_name
        FROM foreign_keys_table;
    table_order SYS_REFCURSOR;
    table_name VARCHAR2(30);
BEGIN
    DELETE FROM order_table WHERE 0 = 0;
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
        INSERT INTO order_table (rec.table_name) VALUES (rec.table_name);
        DBMS_OUTPUT.PUT_LINE(rec.table_name);
    END LOOP;
END;
/

DECLARE
  symbol VARCHAR2(1);
  col_name VARCHAR2(30);
  col_type VARCHAR2(30);
  table_name VARCHAR2(30);
BEGIN
    -- compare table 
    compare_all_tables('C##FULLHAT', 'C##PAN_KROLIC');
END;
/

--DROP TABLE foreign_keys_table;
CREATE TABLE foreign_keys_table (table_name VARCHAR2(30), column_name VARCHAR2(30), constraint_name VARCHAR2(30), r_table_name VARCHAR2(30), owner VARCHAR2(30));
DELETE foreign_keys_table WHERE 0 = 0;

EXECUTE get_foreign_keys('C##PAN_KROLIC');

CREATE TABLE order_table (table_name VARCHAR2(30));
EXECUTE order_tables(1);


