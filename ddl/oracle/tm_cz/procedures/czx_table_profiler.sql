--
-- Type: PROCEDURE; Owner: TM_CZ; Name: CZX_TABLE_PROFILER
--
  CREATE OR REPLACE PROCEDURE "TM_CZ"."CZX_TABLE_PROFILER" 
(
  V_TABLE in varchar2 default null ,
  NBRROWS IN NUMBER DEFAULT 100
)
AS
   /*
   	file: czx_table_profiler.sql
   	desc: Profiles the data and structure of a specific table.
   	KCR@20100614 - Created Script
   	Copyright Ac 2010 Recombinant Data Corp
   	*/
   v_columnName VARCHAR2(250);
   v_dataType VARCHAR2(250);
   v_maxLength VARCHAR2(250);
   v_precision VARCHAR2(250);
   v_scale VARCHAR2(250);
   v_dynamicSQL VARCHAR2(8000);
   v_dynamicCursor VARCHAR2(8000);
   V_VIEWNAME varchar2(250);
   RCOUNT integer ;
  
   
   
   -- Converting data to varchar for dynamic scripts
   v_v_record_sample_percent VARCHAR2(3);
   
   cursor ProfileTable is
      select COLUMN_NAME, DATA_TYPE, DATA_LENGTH, DATA_PRECISION, DATA_SCALE
      from user_tab_columns 
      where table_name = v_table and column_name not in 
            (select column_name from cz_data_profile_column_exclusi where table_name = v_table )
      order by column_name;

-- Can be 1 to 100% (Default is 100)
begin
   
  v_viewName := 'xxx_' || v_table || '_view' ;
   
   --Building a View to use a sample of data
   v_dynamicSQL := 'create or replace view ' || v_viewName || ' as' ||
                  ' select  *   from ' || V_TABLE || ' WHERE ROWNUM < ' || NBRROWS ;
   dbms_output.put_line(v_dynamicSQL);
   EXECUTE IMMEDIATE(v_dynamicSQL);
   
   
   --Delete the existing stats on the tables
   DELETE CZ_DATA_PROFILE_STATS WHERE table_name = v_table;
    
   --Delete the existing stats for this table
   DELETE CZ_DATA_PROFILE_COLUMN_SAMPLE  WHERE table_name = v_table;
   
   OPEN ProfileTable;
   FETCH ProfileTable INTO v_columnName,v_dataType,v_maxLength,v_precision,v_scale;
   WHILE ProfileTable%FOUND
   LOOP

      BEGIN
         --Get a count of Null values or blank values
         v_dynamicSQL := 'INSERT INTO CZ_DATA_PROFILE_STATS' || ' (table_name, column_name, data_type, column_length, column_precision, column_scale, null_count)' || ' select ''' || v_table || ''', ''' || v_columnName || ''', ''' || v_dataType || ''', ' || v_maxLength || ', ' || v_precision || ', ' || v_scale || ', count(*)' || ' from ' || v_viewName || ' where ' || v_columnName || ' is null or ltrim(rtrim(' || v_columnName || ')) = ''''' ;
         DBMS_OUTPUT.PUT_LINE(V_DYNAMICSQL);
          EXECUTE IMMEDIATE (v_dynamicSQL);
         
         --Get a count of Non Null values
         v_dynamicSQL := 'UPDATE CZ_DATA_PROFILE_STATS' || ' set non_null_count = (' || ' select count(*)' || ' from ' || v_viewName || ' where ' || v_columnName || ' is not null AND ltrim(rtrim(' || v_columnName || ')) != '''')' || ' where table_name = ''' || v_table || '''' || ' and column_name = ''' || v_columnName || '''' ;
         DBMS_OUTPUT.PUT_LINE(V_DYNAMICSQL);
 
         EXECUTE IMMEDIATE (v_dynamicSQL);
         
         --get a count of Distinct Values
         v_dynamicSQL := 'UPDATE CZ_DATA_PROFILE_STATS' || ' set distinct_count = (' || ' select count(distinct ' || v_columnName || ')' || ' from ' || v_viewName || ' where ' || v_columnName || ' is not null and ltrim(rtrim(' || v_columnName || ')) != '''')' || ' where table_name = ''' || v_table || '''' || ' and column_name = ''' || v_columnName || '''' ;
          DBMS_OUTPUT.PUT_LINE(V_DYNAMICSQL);
          EXECUTE IMMEDIATE (v_dynamicSQL);
         
         --get max length
         v_dynamicSQL := 'UPDATE CZ_DATA_PROFILE_STATS' || ' set max_length = (' || ' select max(len(ltrim(rtrim(' || v_columnName || '))))' || ' from ' || v_viewName || ' where ' || v_columnName || ' is not null and ltrim(rtrim(' || v_columnName || ')) != '''')' || ' where table_name = ''' || v_table || '''' || ' and column_name = ''' || v_columnName || '''' ;
         EXECUTE IMMEDIATE (v_dynamicSQL);
         
         --get min length
         v_dynamicSQL := 'UPDATE CZ_DATA_PROFILE_STATS' || ' set min_length = (' || ' select min(len(ltrim(rtrim(' || v_columnName || '))))' || ' from ' || v_viewName || ' where ' || v_columnName || ' is not null and ltrim(rtrim(' || v_columnName || ')) != '''')' || ' where table_name = ''' || v_table || '''' || ' and column_name = ''' || v_columnName || '''' ;
         DBMS_OUTPUT.PUT_LINE(V_DYNAMICSQL);
          EXECUTE IMMEDIATE (v_dynamicSQL);
         
         --get max length value
         v_dynamicSQL := 'UPDATE CZ_DATA_PROFILE_STATS' || ' set max_length_value = (' || ' select top 1 ltrim(rtrim(' || v_columnName || '))' || ' from ' || v_viewName || ' where ' || v_columnName || ' is not null and ltrim(rtrim(' || v_columnName || ')) != ''''' || ' and len(ltrim(rtrim(' || v_columnName || '))) = CZ_DATA_PROFILE_STATS.max_length)' || ' where table_name = ''' || v_table || '''' || ' and column_name = ''' || v_columnName || '''' ;
         DBMS_OUTPUT.PUT_LINE(V_DYNAMICSQL);
          EXECUTE IMMEDIATE (v_dynamicSQL);
         
         --get min length value
         v_dynamicSQL := 'UPDATE CZ_DATA_PROFILE_STATS' || ' set min_length_value = (' || ' select top 1 ltrim(rtrim(' || v_columnName || '))' || ' from ' || v_viewName || ' where ' || v_columnName || ' is not null and ltrim(rtrim(' || v_columnName || ')) != ''''' || ' and len(ltrim(rtrim(' || v_columnName || '))) = CZ_DATA_PROFILE_STATS.min_length)' || ' where table_name = ''' || v_table || '''' || ' and column_name = ''' || v_columnName || '''' ;
          DBMS_OUTPUT.PUT_LINE(V_DYNAMICSQL);
          EXECUTE IMMEDIATE (v_dynamicSQL);
         
         --get First value when sorted
         v_dynamicSQL := 'UPDATE CZ_DATA_PROFILE_STATS' || ' set first_value = (' || ' select top 1 ltrim(rtrim(' || v_columnName || '))' || ' from ' || v_viewName || ' where ' || v_columnName || ' is not null and ltrim(rtrim(' || v_columnName || ')) != ''''' || ' order by ltrim(rtrim(' || v_columnName || ')))' || ' where table_name = ''' || v_table || '''' || ' and column_name = ''' || v_columnName || '''' ;
          DBMS_OUTPUT.PUT_LINE(V_DYNAMICSQL);
          EXECUTE IMMEDIATE (v_dynamicSQL);
         
         --get last values when sorted
         v_dynamicSQL := 'UPDATE CZ_DATA_PROFILE_STATS' || ' set last_value = (' || ' select top 1 ltrim(rtrim(' || v_columnName || '))' || ' from ' || v_viewName || ' where ' || v_columnName || ' is not null and ltrim(rtrim(' || v_columnName || ')) != ''''' || ' order by ltrim(rtrim(' || v_columnName || '))' || ' desc)' || ' where table_name = ''' || v_table || '''' || ' and column_name = ''' || v_columnName || '''' ;
          DBMS_OUTPUT.PUT_LINE(V_DYNAMICSQL);
          EXECUTE IMMEDIATE (v_dynamicSQL);
         
         -- Get the top 250 values and the count for each column
         v_dynamicSQL := 'INSERT INTO CZ_DATA_PROFILE_COLUMN_SAMPLE' || ' (table_name, column_name, value, count)' || ' select * ''' || v_table || ''', ''' || v_columnName || ''', ltrim(rtrim(' || v_columnName || ')),  count(*)' || ' from ' || v_viewName || ' where ' || v_columnName || ' is not null and ltrim(rtrim(' || v_columnName || ')) != ''''' || ' and ' || v_columnName || ' not like ''%timestamp%''' || ' and ' || v_columnName || ' not like ''%_by%''' || ' group by ltrim(rtrim(' || v_columnName || '))' ;
          DBMS_OUTPUT.PUT_LINE(V_DYNAMICSQL);
          EXECUTE IMMEDIATE (v_dynamicSQL);
         
         FETCH ProfileTable INTO v_columnName,v_dataType,v_maxLength,v_precision,v_scale;
      END;
   END LOOP;
   CLOSE ProfileTable;
   
   --drop temporary view
   v_dynamicSQL := 'drop view ' || v_viewName ;
   EXECUTE IMMEDIATE (v_dynamicSQL);
END;
/
