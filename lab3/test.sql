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

