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

