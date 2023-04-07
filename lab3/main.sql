--CREATE TABLE temp_table (symbol VARCHAR2(1), col_name VARCHAR2(30), col_type VARCHAR2(30), table_name VARCHAR2(30));

SELECT * FROM temp_table;

SELECT * FROM order_table;

DECLARE
    schema1 VARCHAR2(30) := 'C##dev';
    schema2 VARCHAR2(30) := 'C##prod';
    
    table_name1 VARCHAR2(30);
    table_name2 VARCHAR2(30);
    table_cur1 SYS_REFCURSOR;
    table_cur2 SYS_REFCURSOR;
    
    -- For table
    col_name VARCHAR2(30);
    col_type VARCHAR2(30);
    match_count NUMBER;
    symbol VARCHAR2(1);
    out_cur SYS_REFCURSOR;
    
    -- For order
    table_order SYS_REFCURSOR;
    table_name VARCHAR2(30);
    
    -- For ddl
    v_count NUMBER;
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
    
    DBMS_OUTPUT.put_line(table_name1);
        
    -- Loop indefinitely while fetching table names from the cursor
    LOOP
        EXIT WHEN table_cur1%NOTFOUND OR table_cur2%NOTFOUND;
        
        DBMS_OUTPUT.put_line('compare ' || table_name1 || ' and ' || table_name2);
        
        IF table_name1 = 'TEMP_TABLE' OR table_name1 = 'FOREIGN_KEYS_TABLE' OR table_name1 = 'ORDER_TABLE' THEN
            FETCH table_cur1 INTO table_name1;
            CONTINUE;
        END IF;
        
        IF table_name2 = 'TEMP_TABLE' OR table_name2 = 'FOREIGN_KEYS_TABLE' OR table_name2 = 'ORDER_TABLE' THEN
            FETCH table_cur2 INTO table_name2;
            CONTINUE;
        END IF;
        
        IF table_name1 = table_name2 THEN
            --------------------------------------------------------------------------------
              -- Check if both tables exist
              SELECT COUNT(*) INTO match_count
              FROM all_tables
              WHERE (owner = schema1 AND table_name = table_name1)
                OR (owner = schema2 AND table_name = table_name2);
                
                DBMS_OUTPUT.put_line(match_count);
                
              IF match_count < 2 THEN
                RAISE_APPLICATION_ERROR(-20001, 'One or both tables do not exist in the specified schemas');
              END IF;
              
              -- Compare column structures
              OPEN out_cur FOR
                SELECT '+' AS symbol, column_name AS col_name, data_type AS col_type
                FROM all_tab_cols
                WHERE owner = schema1 AND table_name = table_name1
                MINUS
                SELECT '+' AS symbol, column_name, data_type
                FROM all_tab_cols
                WHERE owner = schema2 AND table_name = table_name2
                UNION ALL
                SELECT '-' AS symbol, column_name, data_type
                FROM all_tab_cols
                WHERE owner = schema2 AND table_name = table_name2
                MINUS
                SELECT '-' AS symbol, column_name, data_type
                FROM all_tab_cols
                WHERE owner = schema1 AND table_name = table_name1;
                
              LOOP
                FETCH out_cur INTO symbol, col_name, col_type;
                EXIT WHEN out_cur%NOTFOUND;
                INSERT INTO temp_table VALUES (symbol, col_name, col_type, table_name1);
              END LOOP;
              --------------------------------------------------------------------------------
            
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
        IF table_name1 = 'TEMP_TABLE' OR table_name1 = 'FOREIGN_KEYS_TABLE' OR table_name1 = 'ORDER_TABLE' THEN
            FETCH table_cur1 INTO table_name1;
            CONTINUE;
        END IF;
        INSERT INTO temp_table VALUES ('+', '~', '~', table_name1);
        DBMS_OUTPUT.put_line('Unique ' || table_name1);
        FETCH table_cur1 INTO table_name1;
    END LOOP;
    
    LOOP
        EXIT WHEN table_cur2%NOTFOUND;
        IF table_name2 = 'TEMP_TABLE' OR table_name2 = 'FOREIGN_KEYS_TABLE' OR table_name2 = 'ORDER_TABLE' THEN
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
    
    ------------------------------------------------------------------------------
    DELETE foreign_keys_table WHERE 0 = 0;
    FOR rec IN (
        SELECT a.table_name, a.column_name, a.constraint_name, c_pk.table_name r_table_name
            FROM all_cons_columns a
        JOIN all_constraints c ON a.owner = c.owner
            AND a.constraint_name = c.constraint_name
        JOIN all_constraints c_pk ON c.r_owner = c_pk.owner
            AND c.r_constraint_name = c_pk.constraint_name
        WHERE c.constraint_type = 'R' AND c.owner = schema1
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
        schema1
    );
    END LOOP;
    
    ----------------------------------------------------------------------
    
    DELETE order_table WHERE 0 = 0;
    
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
        INSERT INTO order_table (table_name) VALUES (rec.table_name);
        DBMS_OUTPUT.PUT_LINE(rec.table_name);
    END LOOP;
    
    -- Drop tables
    FOR r IN (SELECT table_name FROM temp_table WHERE symbol = '-' AND col_name = '~')
    LOOP
        DBMS_OUTPUT.PUT_LINE('DROP TABLE ' || r.table_name || ';');
        DELETE temp_table WHERE symbol = '-' AND col_name = '~';
    END LOOP;
    
    -- Create tables
    FOR r IN (SELECT table_name FROM order_table)
    LOOP
        SELECT COUNT(*) INTO v_count FROM temp_table WHERE symbol = '+' AND col_name = '~' AND table_name = r.table_name;
        IF v_count > 0 THEN
            DBMS_OUTPUT.put_line('CREATE TABLE ' || r.table_name || ' AS SELECT * FROM C##FULL_HAT.' || r.table_name || ' WHERE 1=0;');
        END IF;
    END LOOP;
    
    FOR r IN (SELECT table_name FROM temp_table WHERE symbol = '+' AND col_name = '~')
    LOOP
        SELECT COUNT(*) INTO v_count FROM order_table WHERE table_name = r.table_name;
        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('CREATE TABLE ' || r.table_name || ' AS SELECT * FROM C##FULL_HAT.' || r.table_name || ' WHERE 1=0;');
        END IF;
    END LOOP;
    
    DELETE temp_table WHERE symbol = '+' AND col_name = '~';
    
    -- Alter tables
    FOR r IN (SELECT symbol, col_name, col_type, table_name FROM temp_table)
    LOOP
        IF r.symbol = '+' THEN
            DBMS_OUTPUT.PUT_LINE('ALTER TABLE ' || r.table_name || ' ADD (' || r.col_name || ' ' || r.col_type || ');');
        ELSIF r.symbol = '-' THEN
            DBMS_OUTPUT.PUT_LINE('ALTER TABLE ' || r.table_name || ' DROP COLUMN ' || r.col_name || ';');
        END IF;
    END LOOP;
END;
/

