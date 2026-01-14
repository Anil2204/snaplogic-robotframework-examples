*** Settings ***
Documentation       P1 CORE :: DB2 → CSV → Left Join → S3 :: E2E Validation

Library             Collections
Library             OperatingSystem

Resource            snaplogic_common_robot/snaplogic_apis_keywords/snaplogic_keywords.resource

Suite Setup         Suite Initialization
Suite Teardown      Suite Cleanup


*** Variables ***
${PROJECT_SPACE}               anil-automation-ps
${PROJECT_PATH}                anil-automation-ps/anil_project
${PIPELINES_LOCATION_PATH}     ${PROJECT_PATH}
${ACCOUNT_LOCATION_PATH}       anil-automation-ps/shared
${UNIQUE_ID}                   ANIL_DB2_LEFTJOIN_E2E

${GROUNDPLEX_NAME}             anil-groundplex-automation
${GROUNDPLEX_LOCATION_PATH}    anil-automation-ps/shared

${PIPELINE_NAME}               CAAP_DB2_S3csv_Join
${PIPELINE_FILE_NAME}          CAAP_DB2_S3csv_Join.slp
${TASK_NAME}                   db2_s3_csv_leftjoin_task

${DB2_ACCOUNT_PAYLOAD_FILE}    acc_db2.json
${DB2_ACCOUNT_NAME}            db2_acct

${S3_ACCOUNT_PAYLOAD_FILE}     acc_s3.json
${S3_ACCOUNT_NAME}             minio_account
${S3_BUCKET}                   anil-bucket


*** Test Cases ***

Create DB2 Account
    [Tags]    p1    core
    Create Account From Template
    ...    ${ACCOUNT_LOCATION_PATH}
    ...    ${DB2_ACCOUNT_PAYLOAD_FILE}
    ...    ${DB2_ACCOUNT_NAME}

Create S3 Account
    [Tags]    p1    core
    Create Account From Template
    ...    ${ACCOUNT_LOCATION_PATH}
    ...    ${S3_ACCOUNT_PAYLOAD_FILE}
    ...    ${S3_ACCOUNT_NAME}

Import Pipeline And Create Task
    [Tags]    p1    core
    Import Pipelines From Template
    ...    ${UNIQUE_ID}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${PIPELINE_NAME}
    ...    ${PIPELINE_FILE_NAME}

    Create Triggered Task From Template
    ...    ${UNIQUE_ID}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${PIPELINE_NAME}
    ...    ${TASK_NAME}
    ...    ${GROUNDPLEX_NAME}

Execute Pipeline Task
    [Tags]    p1    core
    Run Triggered Task With Parameters From Template
    ...    ${UNIQUE_ID}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${PIPELINE_NAME}
    ...    ${TASK_NAME}

Validate S3 Output Exists
    [Tags]    p1    core    validation
    S3 Bucket Should Exist    ${S3_BUCKET}


*** Keywords ***
Suite Initialization
    Log    Initializing DB2 → CSV → Left Join → S3 E2E Suite

Suite Cleanup
    Log    Cleaning up DB2 → CSV → Left Join → S3 E2E Suite
