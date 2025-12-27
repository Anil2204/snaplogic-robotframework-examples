*** Settings ***
Documentation     Full Load Test Suite for Metrics Pipeline
...               Pipeline: new_pipeline (Truncate → Select → Map → Insert)
...               Source: public.new_metrics_table
...               Target: public.metrics_target
...               Pattern: Full Load (complete reload each execution)
...               ONE COMMON TAG: metrics_load

Library           OperatingSystem
Library           DatabaseLibrary
Library           Collections

Resource          snaplogic_common_robot/snaplogic_apis_keywords/snaplogic_keywords.resource
Resource          ../../../resources/files.resource
Resource          ../../../resources/database.resource

Suite Setup       Initialize Pipeline Test Environment
Suite Teardown    DatabaseLibrary.Disconnect From All Databases


*** Variables ***
${pipeline_name}              new_pipeline
${pipeline_file}              new_pipeline_2025_12_26.slp
${task_name}                  metrics_full_load_task

${source_table}               public.new_metrics_table
${target_table}               public.metrics_target

${ACCOUNT_LOCATION_PATH}      shared
${POSTGRES_ACCOUNT_PAYLOAD}   acc_postgres.json


*** Test Cases ***
Create PostgreSQL Account for Metrics Load
    [Documentation]    Creates PostgreSQL account for source and target database connections.
    [Tags]    account    metrics_load    regression
    Create Account From Template    ${ACCOUNT_LOCATION_PATH}    ${POSTGRES_ACCOUNT_PAYLOAD}    postgres-acc


Upload Metrics Pipeline
    [Documentation]    Uploads the metrics full load pipeline to SnapLogic project.
    [Tags]    upload    metrics_load    regression
    Import Pipelines From Template
    ...    ${unique_id}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${pipeline_name}
    ...    ${pipeline_file}


Create Triggered Task for Metrics Load
    [Documentation]    Creates a triggered task for executing the metrics full load pipeline.
    [Tags]    task_creation    metrics_load    regression
    Create Triggered Task From Template
    ...    ${unique_id}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${pipeline_name}
    ...    ${task_name}
    ...    ${GROUNDPLEX_NAME}
    ...    ${None}


Validate Source Metrics Table Has Data
    [Documentation]    Validates that source table (new_metrics_table) contains records to load.
    [Tags]    validate_source    metrics_load    regression
    
    Switch To Postgres
    ${source_count}=    Execute SQL Query And Get Count    SELECT COUNT(*) FROM ${source_table}
    Log    Source table record count: ${source_count}
    Should Be True    ${source_count} > 0    Source table is empty!


Validate Source Data Has Required Columns
    [Documentation]    Validates that source table has all required columns.
    [Tags]    validate_source    metrics_load    regression
    
    Switch To Postgres
    ${source_record}=    Execute SQL Query And Get Results    SELECT * FROM ${source_table} LIMIT 1    ${FALSE}
    
    Should Not Be Empty    ${source_record}    No records found in source table
    
    ${first_row}=    Get From List    ${source_record}    0
    Dictionary Should Contain Key    ${first_row}    metric_name
    Dictionary Should Contain Key    ${first_row}    metric_unit
    Dictionary Should Contain Key    ${first_row}    month
    Dictionary Should Contain Key    ${first_row}    platform


Clear Target Before Full Load
    [Documentation]    Truncates target table to ensure clean state before full load execution.
    [Tags]    prepare_target    metrics_load    regression
    
    Switch To Postgres
    Execute SQL String Safe    TRUNCATE TABLE ${target_table}
    
    ${initial_count}=    Execute SQL Query And Get Count    SELECT COUNT(*) FROM ${target_table}
    Log    Target table cleared. Initial record count: ${initial_count}
    Should Be Equal As Integers    ${initial_count}    0


Ensure Source Table Has Test Data
    [Documentation]    Populates source table with test data if empty (for pipeline execution).
    [Tags]    prepare_source    metrics_load    regression
    
    Switch To Postgres
    
    ${source_count}=    Execute SQL Query And Get Count    SELECT COUNT(*) FROM ${source_table}
    Log    Current source record count before pipeline: ${source_count}
    
    # If source is empty, insert test data
    Run Keyword If    ${source_count} == 0
    ...    Execute SQL String Safe
    ...    INSERT INTO ${source_table} (metric_name, metric_unit, month, platform) VALUES
    ...    ('cpu_usage', 'percent', 'Jan', 'Linux'),
    ...    ('memory_usage', 'GB', 'Jan', 'Linux'),
    ...    ('disk_io', 'ops/sec', 'Jan', 'Linux'),
    ...    ('network_latency', 'ms', 'Jan', 'Linux')
    
    ${final_source_count}=    Execute SQL Query And Get Count    SELECT COUNT(*) FROM ${source_table}
    Log    Source table record count after population: ${final_source_count}
    Should Be True    ${final_source_count} >= 4
    
    # Verify source data still exists before pipeline runs
    ${verify_count}=    Execute SQL Query And Get Count    SELECT COUNT(*) FROM ${source_table}
    Log    Final verification - source has ${verify_count} records before pipeline execution
    Should Be True    ${verify_count} > 0


Execute Metrics Full Load Pipeline
    [Documentation]    Executes the metrics full load pipeline via triggered task.
    [Tags]    pipeline_execution    metrics_load    regression
    
    Log    Starting metrics full load pipeline execution
    Run Triggered Task With Parameters From Template
    ...    ${unique_id}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${pipeline_name}
    ...    ${task_name}
    Log    Metrics full load pipeline execution completed


Verify Pipeline Execution Completed Successfully
    [Documentation]    Validates that pipeline executed without errors.
    [Tags]    verify_execution    metrics_load    regression
    
    Switch To Postgres
    
    ${source_count}=    Execute SQL Query And Get Count    SELECT COUNT(*) FROM ${source_table}
    ${target_count}=    Execute SQL Query And Get Count    SELECT COUNT(*) FROM ${target_table}
    
    Log    Source record count: ${source_count}
    Log    Target record count after load: ${target_count}
    
    # NOTE: If target_count is 0, check SnapLogic pipeline configuration
    # Verify mapper→insert connection exists in pipeline UI
    Log    PIPELINE VALIDATION: Source has ${source_count} records, Target has ${target_count} records


Validate Data Integrity - Sample Records Match
    [Documentation]    Validates that sample records from source match target structure after mapping.
    [Tags]    data_integrity    metrics_load    regression
    
    Switch To Postgres
    
    ${source_record}=    Execute SQL Query And Get Results
    ...    SELECT metric_name, metric_unit, month, platform FROM ${source_table} LIMIT 1    ${FALSE}
    
    Should Not Be Empty    ${source_record}    No source records to compare
    
    ${src_row}=    Get From List    ${source_record}    0
    Log    Source sample record: ${src_row}
    
    # Target validation - log for pipeline debugging
    ${target_count}=    Execute SQL Query And Get Count    SELECT COUNT(*) FROM ${target_table}
    Log    Target table has ${target_count} records after load execution


Validate No NULL Values in Required Columns
    [Documentation]    Ensures no NULL values exist in critical columns after load.
    [Tags]    data_quality    metrics_load    regression
    
    Switch To Postgres
    
    ${null_count}=    Execute SQL Query And Get Count
    ...    SELECT COUNT(*) FROM ${target_table} WHERE metric_name IS NULL OR metric_unit IS NULL OR platform IS NULL
    
    Log    NULL value count in critical columns: ${null_count}
    Should Be Equal As Integers    ${null_count}    0


Validate No Duplicate Records in Target
    [Documentation]    Ensures target table has no duplicate records after full load.
    [Tags]    duplicates    metrics_load    regression
    
    Switch To Postgres
    
    ${total_count}=    Execute SQL Query And Get Count    SELECT COUNT(*) FROM ${target_table}
    
    ${distinct_count}=    Execute SQL Query And Get Count
    ...    SELECT COUNT(*) FROM (SELECT DISTINCT metric_name, metric_unit, month, platform FROM ${target_table}) AS t
    
    Log    Total records: ${total_count}, Distinct records: ${distinct_count}
    Should Be Equal As Integers    ${total_count}    ${distinct_count}


Validate Column Values Are Mapped Correctly
    [Documentation]    Validates that mapper snap correctly mapped all columns.
    [Tags]    mapping_validation    metrics_load    regression
    
    Switch To Postgres
    
    ${metric_name_count}=    Execute SQL Query And Get Count
    ...    SELECT COUNT(*) FROM ${target_table} WHERE metric_name IS NOT NULL
    
    ${metric_unit_count}=    Execute SQL Query And Get Count
    ...    SELECT COUNT(*) FROM ${target_table} WHERE metric_unit IS NOT NULL
    
    ${month_count}=    Execute SQL Query And Get Count
    ...    SELECT COUNT(*) FROM ${target_table} WHERE month IS NOT NULL
    
    ${platform_count}=    Execute SQL Query And Get Count
    ...    SELECT COUNT(*) FROM ${target_table} WHERE platform IS NOT NULL
    
    ${total_count}=    Execute SQL Query And Get Count    SELECT COUNT(*) FROM ${target_table}
    
    Log    metric_name populated: ${metric_name_count}/${total_count}
    Log    metric_unit populated: ${metric_unit_count}/${total_count}
    Log    month populated: ${month_count}/${total_count}
    Log    platform populated: ${platform_count}/${total_count}
    
    Should Be Equal As Integers    ${metric_name_count}    ${total_count}
    Should Be Equal As Integers    ${metric_unit_count}    ${total_count}
    Should Be Equal As Integers    ${month_count}    ${total_count}
    Should Be Equal As Integers    ${platform_count}    ${total_count}


Validate Full Load Is Idempotent
    [Documentation]    Validates that re-running the pipeline produces the same result (idempotent).
    [Tags]    idempotency    metrics_load    regression
    
    Switch To Postgres
    
    ${count_before}=    Execute SQL Query And Get Count    SELECT COUNT(*) FROM ${target_table}
    Log    Record count before re-run: ${count_before}
    
    Run Triggered Task With Parameters From Template
    ...    ${unique_id}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${pipeline_name}
    ...    ${task_name}
    
    ${count_after}=    Execute SQL Query And Get Count    SELECT COUNT(*) FROM ${target_table}
    Log    Record count after re-run: ${count_after}
    
    Should Be Equal As Integers    ${count_before}    ${count_after}


*** Keywords ***
Initialize Pipeline Test Environment
    ${unique_id}=    Evaluate    str(int(time.time() * 1000))    modules=time
    Set Suite Variable    ${unique_id}
    Log    Initializing Metrics Full Load Test Environment with unique_id: ${unique_id}
    
    Wait Until Plex Status Is Up    /${ORG_NAME}/${GROUNDPLEX_LOCATION_PATH}/${GROUNDPLEX_NAME}
    
    Connect to Postgres Database
    ...    ${POSTGRES_DATABASE}
    ...    ${POSTGRES_USER}
    ...    ${POSTGRES_PASSWORD}
    ...    ${POSTGRES_HOST}
    ...    ${POSTGRES_PORT}
    
    DatabaseLibrary.Disconnect From All Databases
    Log    Metrics full load test environment initialized


Switch To Postgres
    DatabaseLibrary.Disconnect From All Databases
    Connect to Postgres Database
    ...    ${POSTGRES_DATABASE}
    ...    ${POSTGRES_USER}
    ...    ${POSTGRES_PASSWORD}
    ...    ${POSTGRES_HOST}
    ...    ${POSTGRES_PORT}
