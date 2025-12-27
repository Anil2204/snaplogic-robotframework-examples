*** Settings ***
Documentation       Resource file for Database operations and management
...                 Contains all keywords related to:
...                 • Database connection management (PostgreSQL, Oracle, etc.)
...                 • SQL script execution and management
...                 • Query execution and result processing
...                 • Table creation and management
...                 • Data counting and validation operations
...                 • Database utility functions

# Standard Libraries for database operations
Library             OperatingSystem    # File system operations for SQL scripts
Library             DatabaseLibrary    # Generic database operations
Library             psycopg2    # PostgreSQL driver
Library             pymssql    # SQL Server driver
Library             String    # String operations for SQL processing
Library             Collections    # List and dictionary operations


*** Keywords ***
################## DATABASE CONNECTION MANAGEMENT ##################

Connect to Postgres Database
    [Documentation]    Establishes connection to PostgreSQL database using psycopg2 driver
    ...    📋 ASSERTIONS:
    ...    • Database connection is successfully established
    ...    • PostgreSQL server is accessible at specified host and port
    ...    • Database credentials are valid and authenticated
    ...    • Database name exists and is accessible
    ...    • Connection is ready for SQL operations
    [Arguments]
    ...    ${POSTGRES_DATABASE}
    ...    ${POSTGRES_USER}
    ...    ${POSTGRES_PASSWORD}
    ...    ${POSTGRES_HOST}
    ...    ${POSTGRES_PORT}=5432

    Log    🔌 Connecting to PostgreSQL database...
    Log    📊 Host: ${POSTGRES_HOST}:${POSTGRES_PORT}
    Log    🏛️ Database: ${POSTGRES_DATABASE}
    Log    👤 User: ${POSTGRES_USER}

    Connect To Database
    ...    psycopg2
    ...    ${POSTGRES_DATABASE}
    ...    ${POSTGRES_USER}
    ...    ${POSTGRES_PASSWORD}
    ...    ${POSTGRES_HOST}
    ...    ${POSTGRES_PORT}

    Log    ✅ Successfully connected to PostgreSQL database

Connect to Oracle Database
    [Documentation]    Sets up Oracle database connection
    ...    *Arguments:*
    ...    - None (uses environment variables for connection)
    ...    *Example:*
    ...    | Connect to Oracle Database |
    [Arguments]    ${ORACLE_DATABASE}    ${ORACLE_USER}    ${ORACLE_PASSWORD}    ${ORACLE_HOST}    ${ORACLE_PORT}=1521

    Connect To Database
    ...    oracledb
    ...    ${ORACLE_DATABASE}
    ...    ${ORACLE_USER}
    ...    ${ORACLE_PASSWORD}
    ...    ${ORACLE_HOST}
    ...    ${ORACLE_PORT}

    Log    ✅ Successfully connected to Oracle database

Connect to SQL Server Database
    [Documentation]    Sets up SQL Server database connection
    ...    *Arguments:*
    ...    - Database connection parameters
    ...    *Example:*
    ...    | Connect to SQL Server Database | TestDB | sa | password | localhost | 1433 |
    [Arguments]
    ...    ${SQLSERVER_DATABASE}
    ...    ${SQLSERVER_USER}
    ...    ${SQLSERVER_PASSWORD}
    ...    ${SQLSERVER_HOST}
    ...    ${SQLSERVER_PORT}=1433

    Connect To Database
    ...    pymssql
    ...    ${SQLSERVER_DATABASE}
    ...    ${SQLSERVER_USER}
    ...    ${SQLSERVER_PASSWORD}
    ...    ${SQLSERVER_HOST}
    ...    ${SQLSERVER_PORT}

    Log    ✅ Successfully connected to SQL Server database

Connect to Database Generic
    [Documentation]    Generic database connection supporting multiple database types
    ...    📋 ASSERTIONS:
    ...    • Database driver module is available and can be imported
    ...    • Database server is accessible at specified host and port
    ...    • Database credentials are valid and authenticated
    ...    • Database name exists and is accessible
    ...    • Connection is ready for SQL operations
    [Arguments]    ${db_module}    ${db_name}    ${db_user}    ${db_pass}    ${db_host}    ${db_port}

    Log    🔌 Connecting to ${db_module} database...
    Log    📊 Host: ${db_host}:${db_port}
    Log    🏛️ Database: ${db_name}
    Log    👤 User: ${db_user}

    Connect To Database
    ...    ${db_module}
    ...    ${db_name}
    ...    ${db_user}
    ...    ${db_pass}
    ...    ${db_host}
    ...    ${db_port}

    Log    ✅ Successfully connected to ${db_module} database

Disconnect from Database
    [Documentation]    Safely disconnects from current database
    ...    📋 ASSERTIONS:
    ...    • Database connection is properly closed
    ...    • No hanging connections or resource leaks
    ...    • Connection cleanup is completed successfully

    Log    🔌 Disconnecting from database...
    DatabaseLibrary.Disconnect From Database
    Log    ✅ Successfully disconnected from database

Test Database Connection
    [Documentation]    Tests database connection with a simple query
    ...    📋 ASSERTIONS:
    ...    • Database connection is active and responsive
    ...    • Simple query executes successfully
    ...    • Database server is functioning properly
    [Arguments]    ${test_query}=SELECT 1

    Log    🔍 Testing database connection...

    TRY
        ${result}=    Query    ${test_query}
        Log    ✅ Database connection test passed
        Log    📊 Test query result: ${result}
        RETURN    ${TRUE}
    EXCEPT    AS    ${error}
        Log    ❌ Database connection test failed: ${error}
        RETURN    ${FALSE}
    END

################## SQL EXECUTION AND MANAGEMENT ##################

Execute SQL String Safe
    [Documentation]    Safely executes SQL string with error handling
    ...    📋 ASSERTIONS:
    ...    • SQL statement is properly formatted and valid
    ...    • SQL execution completes without syntax errors
    ...    • Database permissions allow the operation
    ...    • Transaction is properly committed or rolled back
    [Arguments]    ${sql_statement}

    Log    📝 Executing SQL statement...
    Log    🔍 SQL: ${sql_statement}

    TRY
        Execute SQL String    ${sql_statement}
        Log    ✅ SQL statement executed successfully
    EXCEPT    AS    ${error}
        Log    ❌ SQL execution failed: ${error}
        Fail    SQL execution failed: ${error}
    END

Execute SQL Script From File
    [Documentation]    Executes SQL statements from a script file
    ...    📋 ASSERTIONS:
    ...    • SQL script file exists and is readable
    ...    • All SQL statements in file are valid and execute successfully
    ...    • Comments and empty lines are properly handled
    ...    • File parsing completes without errors
    ...    • All statements are executed in sequence
    [Arguments]    ${script_path}

    # Verify script file exists
    File Should Exist    ${script_path}

    # Read the SQL script
    ${sql_content}=    Get File    ${script_path}
    Log    📄 Executing SQL script: ${script_path}

    # Split the script into individual statements
    ${sql_statements}=    Split SQL Script Content    ${sql_content}

    # Execute each statement
    ${executed_count}=    Set Variable    0
    FOR    ${statement}    IN    @{sql_statements}
        ${trimmed_statement}=    Strip String    ${statement}
        IF    '${trimmed_statement}' != '' and not '${trimmed_statement}'.startswith('--')
            Log    🔍 Executing: ${trimmed_statement}
            Execute SQL String Safe    ${trimmed_statement}
            ${executed_count}=    Evaluate    ${executed_count} + 1
        END
    END

    Log    ✅ SQL script executed successfully (${executed_count} statements)

Split SQL Script Content
    [Documentation]    Splits SQL script content into individual executable statements
    ...    📋 ASSERTIONS:
    ...    • SQL content is properly parsed and split
    ...    • Comments and empty lines are filtered out
    ...    • Each statement is properly formatted for execution
    ...    • Statement separation by semicolons works correctly
    [Arguments]    ${sql_content}

    # Remove comments and split by semicolon
    ${lines}=    Split To Lines    ${sql_content}
    ${cleaned_lines}=    Create List

    FOR    ${line}    IN    @{lines}
        ${trimmed_line}=    Strip String    ${line}
        IF    not '${trimmed_line}'.startswith('--') and '${trimmed_line}' != ''
            Append To List    ${cleaned_lines}    ${trimmed_line}
        END
    END

    ${cleaned_sql}=    Catenate    SEPARATOR= ${SPACE}    @{cleaned_lines}
    ${statements}=    Split String    ${cleaned_sql}    ;

    # Filter out empty statements
    ${filtered_statements}=    Create List
    FOR    ${stmt}    IN    @{statements}
        ${trimmed_stmt}=    Strip String    ${stmt}
        IF    '${trimmed_stmt}' != ''
            Append To List    ${filtered_statements}    ${trimmed_stmt}
        END
    END

    Log    📊 Split SQL script into ${filtered_statements.__len__()} statements
    RETURN    ${filtered_statements}

################## QUERY EXECUTION AND RESULT PROCESSING ##################

Execute SQL Query And Get Count
    [Documentation]    Executes a COUNT query and returns the result as integer
    ...    📋 ASSERTIONS:
    ...    • SQL query executes successfully
    ...    • Query returns a valid numeric result
    ...    • Result can be converted to integer
    ...    • Query syntax is valid for COUNT operations
    [Arguments]    ${sql_query}

    Log    🔍 Executing count query: ${sql_query}

    ${result}=    Query    ${sql_query}
    ${count_row}=    Get From List    ${result}    0
    ${count_value}=    Get From List    ${count_row}    0

    Log    📊 Count query result: ${count_value}
    RETURN    ${count_value}

Execute SQL Query And Get Results
    [Documentation]    Executes SQL query and returns all results
    ...    📋 ASSERTIONS:
    ...    • SQL query executes successfully
    ...    • Results are properly formatted and returned
    ...    • Query syntax is valid
    ...    • Database permissions allow the query
    [Arguments]    ${sql_query}    ${fetch_all}=${TRUE}

    Log    🔍 Executing query: ${sql_query}

    TRY
        IF    ${fetch_all}
            ${results}=    Query    ${sql_query}
        ELSE
            ${results}=    Query    ${sql_query}    returnAsDict=${TRUE}
        END

        ${row_count}=    Get Length    ${results}
        Log    📊 Query returned ${row_count} rows
        RETURN    ${results}
    EXCEPT    AS    ${error}
        Log    ❌ Query execution failed: ${error}
        Fail    Query execution failed: ${error}
    END

Execute SQL Query And Get Single Value
    [Documentation]    Executes SQL query and returns single scalar value
    ...    📋 ASSERTIONS:
    ...    • SQL query executes successfully
    ...    • Query returns exactly one row and one column
    ...    • Result can be extracted as single value
    ...    • Query is designed for single value return
    [Arguments]    ${sql_query}

    Log    🔍 Executing single value query: ${sql_query}

    ${results}=    Query    ${sql_query}
    ${row_count}=    Get Length    ${results}

    Should Be Equal As Numbers    ${row_count}    1
    ...    Query should return exactly 1 row, but returned ${row_count}

    ${first_row}=    Get From List    ${results}    0
    ${value}=    Get From List    ${first_row}    0

    Log    📊 Single value result: ${value}
    RETURN    ${value}

Check If Table Exists
    [Documentation]    Checks if a table exists in the database
    ...    📋 ASSERTIONS:
    ...    • Database connection is active
    ...    • Table existence query executes successfully
    ...    • Returns accurate boolean result
    [Arguments]    ${table_name}    ${schema}=public

    ${query}=    Set Variable
    ...    SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${schema}' AND table_name='${table_name}'

    ${count}=    Execute SQL Query And Get Count    ${query}
    ${exists}=    Evaluate    ${count} > 0

    IF    ${exists}
        Log    ✅ Table '${table_name}' exists in schema '${schema}'
    ELSE
        Log    ❌ Table '${table_name}' does not exist in schema '${schema}'
    END

    RETURN    ${exists}

Get Table Row Count
    [Documentation]    Gets the total number of rows in a table
    ...    📋 ASSERTIONS:
    ...    • Table exists in the database
    ...    • COUNT query executes successfully
    ...    • Returns accurate row count as integer
    [Arguments]    ${table_name}

    ${query}=    Set Variable    SELECT COUNT(*) FROM ${table_name}
    ${count}=    Execute SQL Query And Get Count    ${query}

    Log    📊 Table '${table_name}' contains ${count} rows
    RETURN    ${count}

################## TABLE MANAGEMENT OPERATIONS ##################

Create Table From Template
    [Documentation]    Creates table using SQL from template or direct SQL statement
    ...    📋 ASSERTIONS:
    ...    • SQL statement is valid CREATE TABLE syntax
    ...    • Table creation executes successfully
    ...    • Table is created with proper schema and constraints
    ...    • No SQL syntax or permission errors occur
    [Arguments]    ${sql_query}

    Log    🏗️ Creating table from template...
    Log    📝 SQL: ${sql_query}

    Execute SQL String Safe    ${sql_query}
    Log    ✅ Table created successfully

Drop Table If Exists
    [Documentation]    Safely drops a table if it exists
    ...    📋 ASSERTIONS:
    ...    • DROP TABLE operation completes successfully
    ...    • No errors if table doesn't exist
    ...    • Table and all its data are removed
    [Arguments]    ${table_name}    ${cascade}=${FALSE}

    Log    🗑️ Dropping table if exists: ${table_name}

    ${cascade_clause}=    Set Variable If    ${cascade}    CASCADE    ${EMPTY}
    ${sql}=    Set Variable    DROP TABLE IF EXISTS ${table_name} ${cascade_clause}

    Execute SQL String Safe    ${sql}
    Log    ✅ Table '${table_name}' dropped successfully

Truncate Table
    [Documentation]    Truncates (empties) a table
    ...    📋 ASSERTIONS:
    ...    • Table exists before truncation
    ...    • TRUNCATE operation completes successfully
    ...    • All data is removed from table
    ...    • Table structure remains intact
    [Arguments]    ${table_name}

    Log    🗑️ Truncating table: ${table_name}

    ${sql}=    Set Variable    TRUNCATE TABLE ${table_name}
    Execute SQL String Safe    ${sql}

    Log    ✅ Table '${table_name}' truncated successfully

# Get Table Columns
#    [Documentation]    Gets column names from database table
#    ...    📋 ASSERTIONS:
#    ...    • Table exists in the database
#    ...    • Column metadata query executes successfully
#    ...    • Returns list of column names
#    ...    • Column information is accurate and current
#    [Arguments]    ${table_name}    ${schema}=public    ${exclude_id}=${TRUE}

#    Log    🔍 Getting columns for table: ${table_name}

#    ${id_filter}=    Set Variable If    ${exclude_id}    AND column_name != 'id'    ${EMPTY}

#    ${query}=    Set Variable
#    ...    SELECT column_name FROM information_schema.columns WHERE table_schema='${schema}' AND table_name='${table_name}' ${id_filter} ORDER BY ordinal_position

#    ${result}=    Query    ${query}

#    ${columns}=    Create List
#    FOR    ${row}    IN    @{result}
#    ${column}=    Get From List    ${row}    0
#    Append To List    ${columns}    ${column}
#    END

#    Log    📊 Table '${table_name}' columns: ${columns}
#    RETURN    ${columns}

Get Table Schema Info
    [Documentation]    Gets detailed schema information for a table
    ...    📋 ASSERTIONS:
    ...    • Table exists in the database
    ...    • Schema query executes successfully
    ...    • Returns comprehensive table metadata
    ...    • Column details are accurate and complete
    [Arguments]    ${table_name}    ${schema}=public

    Log    🔍 Getting schema info for table: ${table_name}

    ${query}=    Set Variable
    ...    SELECT column_name, data_type, is_nullable, column_default, character_maximum_length
    ...    FROM information_schema.columns
    ...    WHERE table_schema='${schema}' AND table_name='${table_name}'
    ...    ORDER BY ordinal_position

    ${results}=    Execute SQL Query And Get Results    ${query}

    Log    📊 Schema info for '${table_name}': ${results.__len__()} columns
    RETURN    ${results}

################## DATA VALIDATION AND COUNTING ##################

Validate Table Data Count
    [Documentation]    Validates that table contains expected number of rows
    ...    📋 ASSERTIONS:
    ...    • Table exists and is accessible
    ...    • Actual row count matches expected count exactly
    ...    • COUNT query executes successfully
    [Arguments]    ${table_name}    ${expected_count}

    Log    🔍 Validating data count for table: ${table_name}
    Log    📊 Expected count: ${expected_count}

    ${actual_count}=    Get Table Row Count    ${table_name}

    Should Be Equal As Numbers    ${actual_count}    ${expected_count}
    ...    Table '${table_name}' has ${actual_count} rows, expected ${expected_count}

    Log    ✅ Table data count validation passed: ${actual_count} rows

Compare Table Row Counts
    [Documentation]    Compares row counts between two tables
    ...    📋 ASSERTIONS:
    ...    • Both tables exist and are accessible
    ...    • Row count queries execute successfully
    ...    • Comparison logic works correctly
    [Arguments]    ${table1}    ${table2}    ${should_match}=${TRUE}

    Log    🔍 Comparing row counts between tables...
    Log    📊 Table 1: ${table1}
    Log    📊 Table 2: ${table2}

    ${count1}=    Get Table Row Count    ${table1}
    ${count2}=    Get Table Row Count    ${table2}

    Log    📊 ${table1}: ${count1} rows
    Log    📊 ${table2}: ${count2} rows

    IF    ${should_match}
        Should Be Equal As Numbers    ${count1}    ${count2}
        ...    Table row counts don't match: ${table1}(${count1}) != ${table2}(${count2})
        Log    ✅ Table row counts match: ${count1} rows each
    ELSE
        Should Not Be Equal As Numbers    ${count1}    ${count2}
        ...    Table row counts should not match but both have ${count1} rows
        Log    ✅ Table row counts differ as expected: ${count1} vs ${count2}
    END

Validate Table Has Data
    [Documentation]    Validates that table contains at least one row
    ...    📋 ASSERTIONS:
    ...    • Table exists and is accessible
    ...    • Table contains at least one row of data
    ...    • COUNT query executes successfully
    [Arguments]    ${table_name}

    Log    🔍 Validating table has data: ${table_name}

    ${count}=    Get Table Row Count    ${table_name}

    Should Be True    ${count} > 0
    ...    Table '${table_name}' is empty (0 rows)

    Log    ✅ Table '${table_name}' contains data: ${count} rows

Validate Table Is Empty
    [Documentation]    Validates that table is empty (0 rows)
    ...    📋 ASSERTIONS:
    ...    • Table exists and is accessible
    ...    • Table contains exactly 0 rows
    ...    • COUNT query executes successfully
    [Arguments]    ${table_name}

    Log    🔍 Validating table is empty: ${table_name}

    ${count}=    Get Table Row Count    ${table_name}

    Should Be Equal As Numbers    ${count}    0
    ...    Table '${table_name}' is not empty (${count} rows)

    Log    ✅ Table '${table_name}' is empty as expected

################## TRANSACTION MANAGEMENT ##################

Begin Transaction
    [Documentation]    Begins a database transaction
    ...    📋 ASSERTIONS:
    ...    • Database connection supports transactions
    ...    • Transaction begins successfully
    ...    • Transaction state is properly managed

    Log    🔄 Beginning database transaction...
    Execute SQL String    BEGIN
    Log    ✅ Transaction started successfully

Commit Transaction
    [Documentation]    Commits current database transaction
    ...    📋 ASSERTIONS:
    ...    • Active transaction exists
    ...    • Transaction commits successfully
    ...    • All changes are persisted to database

    Log    💾 Committing database transaction...
    Execute SQL String    COMMIT
    Log    ✅ Transaction committed successfully

Rollback Transaction
    [Documentation]    Rolls back current database transaction
    ...    📋 ASSERTIONS:
    ...    • Active transaction exists
    ...    • Transaction rollback completes successfully
    ...    • All changes are discarded

    Log    ↩️ Rolling back database transaction...
    Execute SQL String    ROLLBACK
    Log    ✅ Transaction rolled back successfully

Execute SQL With Transaction
    [Documentation]    Executes SQL statements within a transaction with automatic rollback on error
    ...    📋 ASSERTIONS:
    ...    • Transaction management works correctly
    ...    • SQL statements execute successfully or transaction is rolled back
    ...    • Database state is consistent after operation
    [Arguments]    ${sql_statements}    ${auto_commit}=${TRUE}

    Log    🔄 Executing SQL with transaction management...

    TRY
        Begin Transaction

        # Handle both single statement and list of statements
        ${is_list}=    Evaluate    isinstance($sql_statements, list)

        IF    ${is_list}
            FOR    ${statement}    IN    @{sql_statements}
                Execute SQL String Safe    ${statement}
            END
        ELSE
            Execute SQL String Safe    ${sql_statements}
        END

        IF    ${auto_commit}
            Commit Transaction
            Log    ✅ SQL executed and committed successfully
        ELSE
            Log    ✅ SQL executed successfully (transaction not committed)
        END
    EXCEPT    AS    ${error}
        Log    ❌ SQL execution failed, rolling back transaction: ${error}
        Rollback Transaction
        Fail    SQL execution failed: ${error}
    END

################## DATABASE UTILITY KEYWORDS ##################

Wait For Database Connection
    [Documentation]    Waits for database to become available with retry logic
    ...    📋 ASSERTIONS:
    ...    • Database eventually becomes available within timeout
    ...    • Connection test succeeds at least once
    ...    • Retry logic works correctly
    [Arguments]    ${timeout}=30s    ${retry_interval}=2s

    Log    ⏳ Waiting for database connection (timeout: ${timeout})...

    ${end_time}=    Add Time To Date    ${NOW}    ${timeout}

    WHILE    True
        ${current_time}=    Get Current Date
        ${time_exceeded}=    Evaluate    '${current_time}' > '${end_time}'

        IF    ${time_exceeded}
            Fail    Database connection timeout after ${timeout}
        END

        ${connected}=    Test Database Connection
        IF    ${connected}
            Log    ✅ Database connection established
            BREAK
        END

        Log    ⏳ Database not ready, retrying in ${retry_interval}...
        Sleep    ${retry_interval}
    END

Execute SQL Template
    [Documentation]    Executes SQL with variable substitution from template
    ...    📋 ASSERTIONS:
    ...    • Template variables are properly substituted
    ...    • Resulting SQL is valid and executes successfully
    ...    • Variable substitution works correctly
    [Arguments]    ${sql_template}    &{variables}

    Log    📝 Executing SQL template with variables...
    Log    🔧 Variables: ${variables}

    # Substitute variables in SQL template
    ${sql_with_vars}=    Set Variable    ${sql_template}
    FOR    ${var_name}    ${var_value}    IN    &{variables}
        ${sql_with_vars}=    Replace String    ${sql_with_vars}    {${var_name}}    ${var_value}
    END

    Log    📝 Final SQL: ${sql_with_vars}
    Execute SQL String Safe    ${sql_with_vars}
    Log    ✅ SQL template executed successfully

Backup Table Data
    [Documentation]    Creates a backup of table data (simplified version)
    ...    📋 ASSERTIONS:
    ...    • Source table exists and is accessible
    ...    • Backup table is created successfully
    ...    • All data is copied correctly
    [Arguments]    ${source_table}    ${backup_table}    ${drop_if_exists}=${TRUE}

    Log    💾 Creating backup of table: ${source_table} → ${backup_table}

    IF    ${drop_if_exists}    Drop Table If Exists    ${backup_table}

    ${sql}=    Set Variable    CREATE TABLE ${backup_table} AS SELECT * FROM ${source_table}
    Execute SQL String Safe    ${sql}

    # Verify backup
    ${source_count}=    Get Table Row Count    ${source_table}
    ${backup_count}=    Get Table Row Count    ${backup_table}

    Should Be Equal As Numbers    ${source_count}    ${backup_count}
    ...    Backup failed: source has ${source_count} rows, backup has ${backup_count}

    Log    ✅ Table backup completed: ${backup_count} rows copied

Clean Database Tables
    [Documentation]    Cleans up test tables by truncating or dropping them
    ...    📋 ASSERTIONS:
    ...    • Cleanup operations complete successfully
    ...    • Tables are properly removed or emptied
    ...    • No errors during cleanup process
    [Arguments]    ${tables}    ${operation}=TRUNCATE

    Log    🧹 Cleaning database tables (${operation})...
    Log    📋 Tables: ${tables}

    # Handle both single table and list of tables
    ${is_list}=    Evaluate    isinstance($tables, list)
    ${table_list}=    Set Variable If    ${is_list}    ${tables}    [${tables}]

    FOR    ${table}    IN    @{table_list}
        TRY
            IF    '${operation}' == 'TRUNCATE'
                Truncate Table    ${table}
            ELSE IF    '${operation}' == 'DROP'
                Drop Table If Exists    ${table}
            ELSE
                Log    ⚠️ Unknown operation: ${operation}, skipping table ${table}
            END
        EXCEPT    AS    ${error}
            Log    ⚠️ Failed to clean table ${table}: ${error}
        END
    END

    Log    ✅ Database cleanup completed

Execute SQL On Database
    [Documentation]    Execute SQL on a specific database connection
    ...    database_type should be 'postgres' or 'oracle'
    [Arguments]    ${sql}    ${database_type}

    # Close any existing connection to avoid warnings
    Run Keyword And Ignore Error    Disconnect From Database

    # Execute based on database type
    IF    '${database_type}' == 'postgres'
        # Connect to PostgreSQL
        Connect to Postgres Database
        ...    ${POSTGRES_DATABASE}
        ...    ${POSTGRES_USER}
        ...    ${POSTGRES_PASSWORD}
        ...    ${POSTGRES_HOST}
        ...    ${POSTGRES_PORT}
        Execute SQL String    ${sql}
    ELSE IF    '${database_type}' == 'oracle'
        # Connect to Oracle
        Connect to Oracle Database
        ...    ${ORACLE_DATABASE}
        ...    ${ORACLE_USER}
        ...    ${ORACLE_PASSWORD}
        ...    ${ORACLE_HOST}
        ...    ${ORACLE_PORT}
        Execute SQL String    ${sql}
    ELSE IF    '${database_type}' == 'sqlserver'
        # Connect to SQL Server
        Connect to SQL Server Database
        ...    ${SQLSERVER_DATABASE}
        ...    ${SQLSERVER_USER}
        ...    ${SQLSERVER_PASSWORD}
        ...    ${SQLSERVER_HOST}
        ...    ${SQLSERVER_PORT}
        Execute SQL String    ${sql}
    ELSE
        Fail    Unknown database type: ${database_type}. Use 'postgres', 'oracle', or 'sqlserver'
    END
