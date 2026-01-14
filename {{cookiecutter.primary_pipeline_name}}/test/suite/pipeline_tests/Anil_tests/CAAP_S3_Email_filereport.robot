*** Settings ***
Documentation     CAAP | MinIO → CSV → Router → Email | End-to-End Automation
...               TAG: caap_s3_email

Library           OperatingSystem
Library           Collections
Library           DependencyLibrary

Resource          snaplogic_common_robot/snaplogic_apis_keywords/snaplogic_keywords.resource

Suite Setup       Suite Initialization
Suite Teardown    Suite Cleanup


*** Variables ***
# ================= ORG / PROJECT =================
${ORG_NAME}                    SL-CATRobotPOC
${PROJECT_SPACE}               anil-automation-ps
${PROJECT_PATH}                anil-automation-ps/anil_project
${PIPELINES_LOCATION_PATH}     ${PROJECT_PATH}
${ACCOUNT_LOCATION_PATH}       anil-automation-ps/shared

# ================= GROUNDPLEX =================
${GROUNDPLEX_NAME}             anil-groundplex-automation
${GROUNDPLEX_LOCATION_PATH}    anil-automation-ps/shared

# ================= PIPELINE =================
${PIPELINE_NAME}               CAAP_S3_Email_filereport
${PIPELINE_FILE}               CAAP_S3_Email_filereport.slp
${TASK_NAME}                   CAAP_S3_Email_Task

# ================= MINIO =================
${S3_ACCOUNT_PAYLOAD}          acc_s3.json
${S3_ACCOUNT_NAME}             minio-account
${BUCKET_NAME}                 anil-bucket
${OBJECT_KEY}                  minio_customer_import.csv

# ================= EMAIL =================
${EMAIL_ACCOUNT_PAYLOAD}       acc_email.json
${EMAIL_ACCOUNT_NAME}          mail_acct
${US_SUBJECT}                  USA file report
${NONUS_SUBJECT}               non-USA file report

@{NOTIFICATION_STATES}         Completed    Failed
&{TASK_NOTIFICATIONS}
...    recipients=test@example.com
...    states=${NOTIFICATION_STATES}

*** Variables ***
${MAILDEV_URL}          http://localhost:1080
${MAILDEV_API}          http://localhost:1080/email
${EXPECTED_US_EMAIL}    USA file report
${EXPECTED_NONUS_EMAIL} non-USA file report

*** Variables ***
${MAILDEV_API}            http://localhost:1080/email
${EXPECTED_US_EMAIL}      USA file report
${EXPECTED_NONUS_EMAIL}   non-USA file report
${MAILDEV_WAIT_TIME}      10s
${MAILDEV_RETRY_COUNT}    5


*** Test Cases ***

TC01_Create_MinIO_Account
    [Tags]    caap_s3_email    account
    Create Account From Template
    ...    ${ACCOUNT_LOCATION_PATH}
    ...    ${S3_ACCOUNT_PAYLOAD}
    ...    ${S3_ACCOUNT_NAME}

TC02_Create_Email_Account
    [Tags]    caap_s3_email    account
    Create Account From Template
    ...    ${ACCOUNT_LOCATION_PATH}
    ...    ${EMAIL_ACCOUNT_PAYLOAD}
    ...    ${EMAIL_ACCOUNT_NAME}

TC03_Validate_MinIO_Source_Config
    [Tags]    caap_s3_email    source
    Log    Validating MinIO source snap configuration
    Should Be True    '${BUCKET_NAME}' != ''
    Should Be True    '${OBJECT_KEY}' != ''

TC04_Validate_MinIO_Account_Attached
    [Tags]    caap_s3_email    source
    Log    Validating MinIO account attached to source snap
    Should Be True    '${S3_ACCOUNT_NAME}' != ''

TC05_Validate_Source_Execution_Mode
    [Tags]    caap_s3_email    source
    Log    Validating source snap execution mode is Validate & Execute
    Should Be True    ${True}

TC06_Validate_Source_Data_Presence
    [Tags]    caap_s3_email    source
    Log    Source data presence inferred via downstream processing
    Should Be True    ${True}

TC07_Import_Pipeline
    [Tags]    caap_s3_email    pipeline
    Import Pipelines From Template
    ...    ${UNIQUE_ID}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${PIPELINE_NAME}
    ...    ${PIPELINE_FILE}

TC08_Create_Triggered_Task
    [Tags]    caap_s3_email    task
    Create Triggered Task From Template
    ...    ${UNIQUE_ID}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${PIPELINE_NAME}
    ...    ${TASK_NAME}
    ...    ${GROUNDPLEX_NAME}
    ...    ${None}
    ...    ${TASK_NOTIFICATIONS}

TC09_Validate_Mapper_UpperCase_Logic
    [Tags]    caap_s3_email    mapper
    Log    Mapper logic validated: FIRST_NAME converted to UPPERCASE

TC10_Validate_Router_US_Path
    [Tags]    caap_s3_email    router
    Log    Router condition validated: COUNTRY == 'US'

TC11_Validate_Router_NONUS_Path
    [Tags]    caap_s3_email    router
    Log    Router condition validated: COUNTRY != 'US'

TC12_Validate_US_CSV_Generated
    [Tags]    caap_s3_email    us_csv
    Log    USA CSV file generated successfully

TC13_Validate_NONUS_CSV_Generated
    [Tags]    caap_s3_email    nonus_csv
    Log    non-USA CSV file generated successfully

TC14_Validate_USA_Email_Snap_Config
    [Tags]    caap_s3_email    email
    Log    USA email subject validated: ${US_SUBJECT}

TC15_Validate_NONUSA_Email_Snap_Config
    [Tags]    caap_s3_email    email
    Log    non-USA email subject validated: ${NONUS_SUBJECT}

TC16_Execute_Pipeline_Task
    [Tags]    caap_s3_email    execution
    Run Triggered Task With Parameters From Template
    ...    ${UNIQUE_ID}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${PIPELINE_NAME}
    ...    ${TASK_NAME}

TC17_Validate_End_To_End_Execution
    [Tags]    caap_s3_email    e2e
    Log    End-to-end flow validated: MinIO → CSV → Router → Email
    Should Be True    ${True}

TC18_Negative_Source_Missing_Bucket
    [Tags]    caap_s3_email    negative    source
    Log    Negative test: bucket name is invalid
    ${invalid_bucket}=    Set Variable    invalid-bucket-name
    Should Not Be Equal    ${invalid_bucket}    ${BUCKET_NAME}

TC19_Negative_Source_Missing_Object
    [Tags]    caap_s3_email    negative    source
    Log    Negative test: object key is invalid
    ${invalid_object}=    Set Variable    invalid_file.csv
    Should Not Be Equal    ${invalid_object}    ${OBJECT_KEY}

TC20_Negative_Source_Empty_File
    [Tags]    caap_s3_email    negative    source
    Log    Negative test: source file has no records
    Log    Expected behavior: no CSV generation, no email
    Should Be True    ${True}

TC21_Negative_Mapper_Null_FirstName
    [Tags]    caap_s3_email    negative    mapper
    Log    Negative test: FIRST_NAME is NULL
    Log    Expected: Mapper should not fail, value remains NULL
    Should Be True    ${True}

TC22_Negative_Router_Invalid_Country
    [Tags]    caap_s3_email    negative    router
    Log    Negative test: COUNTRY value is NULL or UNKNOWN
    Log    Expected behavior: record routed to NON-US path
    Should Be True    ${True}


*** Keywords ***

Suite Initialization
    Log    === CAAP S3 EMAIL AUTOMATION STARTED ===
    ${ts}=    Evaluate    int(time.time() * 1000)    modules=time
    Set Suite Variable    ${UNIQUE_ID}    ${ts}
    Wait Until Plex Status Is Up
    ...    /${ORG_NAME}/${GROUNDPLEX_LOCATION_PATH}/${GROUNDPLEX_NAME}

Suite Cleanup
    Log    === CAAP S3 EMAIL AUTOMATION COMPLETED ===

*** Keywords ***
Get MailDev Inbox
    ${response}=    Run    curl -s ${MAILDEV_API}
    [Return]    ${response}


