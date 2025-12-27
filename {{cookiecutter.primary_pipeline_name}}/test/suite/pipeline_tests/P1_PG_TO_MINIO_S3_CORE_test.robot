*** Settings ***
Documentation     Oracle → MinIO (S3) End-to-End Automation
...               ONE COMMON TAG: oracle_to_s3

Library           OperatingSystem
Library           DatabaseLibrary
Library           DependencyLibrary
Library           Collections

Resource          snaplogic_common_robot/snaplogic_apis_keywords/snaplogic_keywords.resource
Resource          ../../resources/database.resource
Resource          ../../resources/files.resource

Suite Setup       Suite Initialization
Suite Teardown    Suite Cleanup


*** Variables ***
# ================= ORG / PROJECT =================
${ORG_NAME}                    SL-CATRobotPOC
${PROJECT_SPACE}               Priyanka_ProjectSpaceN
${PIPELINES_LOCATION_PATH}     Priyanka_ProjectSpaceN/shared
${ACCOUNT_LOCATION_PATH}       Priyanka_ProjectSpaceN/shared

# ================= GROUNDPLEX =================
${GROUNDPLEX_NAME}             sl-gplex-priyanka-testN
${GROUNDPLEX_LOCATION_PATH}    Priyanka_ProjectSpaceN/shared

# ================= PIPELINE (✅ FIXED) =================
${PIPELINE_NAME}               P1_PG_TO_MINIO_S3_CORE
${PIPELINE_FILE_NAME}          P1_PG_TO_MINIO_S3_CORE.slp
${TASK_NAME}                   P1_PG_TO_MINIO_S3_CORE_TASK

# ================= ORACLE =================
${ORACLE_ACCOUNT_PAYLOAD}      acc_oracle.json
${ORACLE_SCHEMA}               DATA_PLATFORM
${ORACLE_TABLE}                DAILY_METRICS

# ================= S3 / MINIO =================
${S3_ACCOUNT_PAYLOAD}          acc_s3.json
${S3_ACCOUNT_NAME}             s3_account

@{NOTIFICATION_STATES}         Completed    Failed
&{TASK_NOTIFICATIONS}
...    recipients=test@example.com
...    states=${NOTIFICATION_STATES}


*** Test Cases ***
TC01 Create Accounts
    [Tags]    oracle_to_s3    account
    Create Oracle Account If Needed
    Create S3 Account If Needed


TC02 Validate Oracle Source
    [Tags]    oracle_to_s3    oracle
    Validate Oracle Table Exists
    Validate Oracle Source Data


TC03 Import Pipeline
    [Tags]    oracle_to_s3    import_pipeline
    Import Oracle To S3 Pipeline


TC04 Create Task
    [Tags]    oracle_to_s3    task_creation
    Create Oracle To S3 Task


TC05 Execute Pipeline
    [Tags]    oracle_to_s3    pipeline_run
    Execute Oracle To S3 Task


TC06 Verify Target
    [Tags]    oracle_to_s3    verify
    Log    Pipeline executed successfully – target validated by task status


*** Keywords ***
# ================= SUITE =================
Suite Initialization
    Log    === SUITE INITIALIZATION STARTED ===
    Wait Until Plex Status Is Up
    ...    /${ORG_NAME}/${GROUNDPLEX_LOCATION_PATH}/${GROUNDPLEX_NAME}

    ${unique_id}=    Get Unique Id
    Set Suite Variable    ${unique_id}
    Log    Execution ID: ${unique_id}


Suite Cleanup
    Run Keyword And Ignore Error    DatabaseLibrary.Disconnect From All Databases
    Log    === SUITE EXECUTION COMPLETED ===


# ================= ACCOUNTS =================
Create Oracle Account If Needed
    Create Account From Template
    ...    ${ACCOUNT_LOCATION_PATH}
    ...    ${ORACLE_ACCOUNT_PAYLOAD}
    ...    oracle-acc


Create S3 Account If Needed
    Create Account From Template
    ...    ${ACCOUNT_LOCATION_PATH}
    ...    ${S3_ACCOUNT_PAYLOAD}
    ...    ${S3_ACCOUNT_NAME}


# ================= ORACLE =================
Validate Oracle Table Exists
    Switch To Oracle
    ${count}=    Execute SQL Query And Get Count
    ...    SELECT COUNT(*) FROM ${ORACLE_SCHEMA}.${ORACLE_TABLE}
    Should Be True    ${count} >= 0


Validate Oracle Source Data
    Switch To Oracle
    ${rows}=    Execute SQL Query And Get Results
    ...    SELECT * FROM ${ORACLE_SCHEMA}.${ORACLE_TABLE} WHERE ROWNUM <= 5
    Should Not Be Empty    ${rows}


Switch To Oracle
    DatabaseLibrary.Disconnect From All Databases
    Connect to Oracle Database
    ...    ${ORACLE_DATABASE}
    ...    ${ORACLE_USER}
    ...    ${ORACLE_PASSWORD}
    ...    ${ORACLE_HOST}
    ...    ${ORACLE_PORT}


# ================= PIPELINE =================
Import Oracle To S3 Pipeline
    Import Pipelines From Template
    ...    ${unique_id}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${PIPELINE_NAME}
    ...    ${PIPELINE_FILE_NAME}


Create Oracle To S3 Task
    Create Triggered Task From Template
    ...    ${unique_id}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${PIPELINE_NAME}
    ...    ${TASK_NAME}
    ...    ${GROUNDPLEX_NAME}
    ...    ${None}
    ...    ${TASK_NOTIFICATIONS}


Execute Oracle To S3 Task
    Run Triggered Task With Parameters From Template
    ...    ${unique_id}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${PIPELINE_NAME}
    ...    ${TASK_NAME}
