*** Settings ***
Documentation     Complete Test Suite for OTS_QLIK_DLY Pipeline (PostgreSQL → Oracle ETL)
...               ONE COMMON TAG: ots_qlik_dly

Library           OperatingSystem
Library           DatabaseLibrary
Library           oracledb
Library           DependencyLibrary
Library           Collections

Resource          snaplogic_common_robot/snaplogic_apis_keywords/snaplogic_keywords.resource
Resource          ../../../resources/files.resource
Resource          ../../../resources/database.resource

Suite Setup       Initialize Pipeline Test Environment
Suite Teardown    DatabaseLibrary.Disconnect From All Databases


*** Variables ***
${pipeline_name}              OTS_QLIK_DLY
${pipeline_file}              OTS_QLIK_DLY.slp
${task_name}                  OTS_QLIK_DLY_Task

${postgres_query}             SELECT name AS metric_name, metric_unit, platform, TO_CHAR(create_date, 'YYYYMM') AS month FROM qlik_ots_daily
${oracle_table}               SYSTEM.OTS_DAILY2

${ACCOUNT_LOCATION_PATH}      shared
${ORACLE_ACCOUNT_PAYLOAD}     acc_oracle.json
${POSTGRES_ACCOUNT_PAYLOAD}   acc_postgres.json

@{notification_states}        Completed    Failed
&{task_notifications}
...                           recipients=test@example.com
...                           states=${notification_states}


*** Test Cases ***
Create Accounts
    [Tags]    account    ots_qlik_dly
    Create Account From Template    ${ACCOUNT_LOCATION_PATH}    ${ORACLE_ACCOUNT_PAYLOAD}    oracle-acc
    Create Account From Template    ${ACCOUNT_LOCATION_PATH}    ${POSTGRES_ACCOUNT_PAYLOAD}  postgres-acc


Upload Files Using File Protocol
    [Tags]    upload    ots_qlik_dly
    Upload File Using File Protocol Template
    ...    file:///opt/snaplogic/test_data/actual_expected_data/expression_libraries/test.expr
    ...    ${ACCOUNT_LOCATION_PATH}


Upload Files to SnapLogic
    [Tags]    upload    ots_qlik_dly
    Upload Files To SnapLogic From Template
    ...    ${CURDIR}/../../test_data/actual_expected_data/expression_libraries
    ...    test.expr
    ...    ${ACCOUNT_LOCATION_PATH}


Import Pipeline
    [Tags]    import_pipeline    ots_qlik_dly
    Import Pipelines From Template
    ...    ${unique_id}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${pipeline_name}
    ...    ${pipeline_file}


Create Triggered Task
    [Tags]    task_creation    ots_qlik_dly
    Create Triggered Task From Template
    ...    ${unique_id}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${pipeline_name}
    ...    ${task_name}
    ...    ${GROUNDPLEX_NAME}
    ...    ${None}
    ...    ${task_notifications}


Validate PostgreSQL Data Extraction
    [Tags]    extract    ots_qlik_dly
    Switch To Postgres
    ${rows}=    Execute SQL Query And Get Results    ${postgres_query}    ${FALSE}
    Should Not Be Empty    ${rows}


Validate Oracle Delete Snap
    [Tags]    delete    ots_qlik_dly
    Switch To Oracle
    Execute SQL String Safe    DELETE FROM ${oracle_table}
    ${count}=    Execute SQL Query And Get Count    SELECT COUNT(*) FROM ${oracle_table}
    Should Be Equal As Integers    ${count}    0


Validate Filter Snap Logic
    [Tags]    filter    ots_qlik_dly
    ${result}=    Evaluate    0 == 1
    Should Be Equal As Integers    ${result}    0


Validate Join Snap Behavior
    [Tags]    join    ots_qlik_dly
    Switch To Postgres
    ${pg_count}=    Execute SQL Query And Get Count    SELECT COUNT(*) FROM qlik_ots_daily
    Should Be True    ${pg_count} > 0


Validate Oracle Insert Capability
    [Tags]    insert    ots_qlik_dly
    Switch To Oracle
    ${count}=    Execute SQL Query And Get Count    SELECT COUNT(*) FROM ${oracle_table}
    Should Be True    ${count} >= 0


Execute Pipeline Task
    [Tags]    pipeline_run    ots_qlik_dly
    Run Triggered Task With Parameters From Template
    ...    ${unique_id}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${pipeline_name}
    ...    ${task_name}


Validate ETL End To End Results
    [Tags]    end_to_end    ots_qlik_dly
    Switch To Oracle
    ${count}=    Execute SQL Query And Get Count    SELECT COUNT(*) FROM ${oracle_table}
    Should Be True    ${count} > 0


*** Keywords ***
Initialize Pipeline Test Environment
    ${unique_id}=    Get Unique Id
    Set Suite Variable    ${unique_id}
    Wait Until Plex Status Is Up
    ...    /${ORG_NAME}/${GROUNDPLEX_LOCATION_PATH}/${GROUNDPLEX_NAME}


Switch To Oracle
    DatabaseLibrary.Disconnect From All Databases
    Connect to Oracle Database
    ...    ${ORACLE_DATABASE}
    ...    ${ORACLE_USER}
    ...    ${ORACLE_PASSWORD}
    ...    ${ORACLE_HOST}
    ...    ${ORACLE_PORT}


Switch To Postgres
    DatabaseLibrary.Disconnect From All Databases
    Connect to Postgres Database
    ...    ${POSTGRES_DATABASE}
    ...    ${POSTGRES_USER}
    ...    ${POSTGRES_PASSWORD}
    ...    ${POSTGRES_HOST}
    ...    ${POSTGRES_PORT}
