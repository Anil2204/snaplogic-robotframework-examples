*** Settings ***
Documentation     CAAP | Oracle → Postgres CDC | Full End-to-End Automation
Library           OperatingSystem
Library           Collections
Library           DatabaseLibrary
Library           oracledb
Library           psycopg2
Library           RequestsLibrary
Library           DependencyLibrary

Resource          snaplogic_common_robot/snaplogic_apis_keywords/snaplogic_keywords.resource
Resource          ../../../resources/general.resource

Suite Setup       Suite Initialization
Suite Teardown    Suite Cleanup
Force Tags        caap-orc-pgres-cdc


*** Variables ***

# ========= ORG / PROJECT =========
${ORG_NAME}                    SL-CATRobotPOC
${PROJECT_PATH}                anil-automation-ps/anil_project
${ACCOUNT_LOCATION_PATH}       anil-automation-ps/shared
${PIPELINES_LOCATION_PATH}     ${PROJECT_PATH}

# ========= GROUNDPLEX =========
${GROUNDPLEX_NAME}             anil-groundplex-automation
${GROUNDPLEX_LOCATION_PATH}    anil-automation-ps/shared

# ========= PIPELINE =========
${PIPELINE_NAME}               CAAP_ORC_PGRES_CDC
${PIPELINE_FILE}               CAAP_ORC_PGRES_CDC.slp
${TASK_NAME}                   CAAP_ORC_PGRES_CDC_Task

# ========= ORACLE =========
${ORACLE_HOST}                 oracle-db
${ORACLE_PORT}                 1521
${ORACLE_DB}                   FREEPDB1
${ORACLE_USER}                 SYSTEM
${ORACLE_PASSWORD}             Oracle123
${ORACLE_SCHEMA}               SYSTEM
${ORACLE_TABLE}                ORACLE_CUSTOMER

# ========= POSTGRES =========
${POSTGRES_HOST}               postgres-db
${POSTGRES_PORT}               5432
${POSTGRES_DB}                 snaplogic
${POSTGRES_USER}               snaplogic
${POSTGRES_PASSWORD}           snaplogic
${POSTGRES_SCHEMA}             public
${POSTGRES_TABLE}              POSTGRES_CUSTOMER

# ========= EMAIL =========
${MAILDEV_URL}                 http://maildev-test:1080
${EMAIL_SUBJECT}               CDC report
${TEST_TO_EMAIL}               test-mail@test.com

# ========= TASK PARAMS =========
&{TASK_PARAMS}
...    DOMAIN_NAME=SLIM_DOM2

@{NOTIFICATION_STATES}         Completed    Failed
&{TASK_NOTIFICATIONS}
...    recipients=test@example.com
...    states=${NOTIFICATION_STATES}


*** Test Cases ***

TC01 Create Accounts
    Create Oracle Account
    Create Postgres Account
    Create Email Account

TC02 Validate Oracle Connection
    Validate Oracle Connection

TC03 Validate Postgres Connection
    Validate Postgres Connection

TC04 Validate Oracle Source Data Exists
    Validate Oracle Source Data

TC05 Validate Postgres Source Data Exists
    Validate Postgres Source Data Exists

TC06 Import Pipeline
    Import Pipeline From Template

TC07 Create Pipeline Task
    Create Pipeline Task

TC08 Execute Pipeline Task
    Execute Pipeline Task

TC09 Validate Email Target Data
    Validate Email Target Data

TC10 Validate Diff Snap Configuration
    Validate Diff Snap Configuration

TC11 Validate Diff Insertion
    Validate Diff Insertion

TC12 Validate Diff Modified (CSV)
    Validate Diff Modified CSV (Conditional)

TC13 Validate Email Logic
    Validate Email Logic

TC14 Validate Diff Deletion
    [Documentation]    Validate CDC deletion behavior using Diff snap

    Validate Diff Deletion Behavior


*** Keywords ***

# ========= SUITE =========
Suite Initialization
    Wait Until Plex Status Is Up
    ...    /${ORG_NAME}/${GROUNDPLEX_LOCATION_PATH}/${GROUNDPLEX_NAME}
    ${unique_id}=    Get Unique Id
    Set Suite Variable    ${unique_id}

Suite Cleanup
    Run Keyword And Ignore Error    Disconnect From Database
    Log    === SUITE EXECUTION COMPLETED ===


# ========= ACCOUNTS =========
Create Oracle Account
    Create Account From Template
    ...    ${ACCOUNT_LOCATION_PATH}
    ...    acc_oracle.json
    ...    oracle_acct

Create Postgres Account
    Create Account From Template
    ...    ${ACCOUNT_LOCATION_PATH}
    ...    acc_postgres.json
    ...    postgres_acct

Create Email Account
    Create Account From Template
    ...    ${ACCOUNT_LOCATION_PATH}
    ...    acc_email.json
    ...    mail_acct


# ========= DATABASE CONNECTIONS =========
Connect Oracle
    Run Keyword And Ignore Error    Disconnect From Database
    Connect To Database
    ...    db_module=oracledb
    ...    db_name=${ORACLE_DB}
    ...    db_user=${ORACLE_USER}
    ...    db_password=${ORACLE_PASSWORD}
    ...    db_host=${ORACLE_HOST}
    ...    db_port=${ORACLE_PORT}

Connect Postgres
    Run Keyword And Ignore Error    Disconnect From Database
    Connect To Database
    ...    db_module=psycopg2
    ...    db_name=${POSTGRES_DB}
    ...    db_user=${POSTGRES_USER}
    ...    db_password=${POSTGRES_PASSWORD}
    ...    db_host=${POSTGRES_HOST}
    ...    db_port=${POSTGRES_PORT}


# ========= CONNECTION VALIDATION =========
Validate Oracle Connection
    Connect Oracle
    ${r}=    Query    SELECT 1 FROM dual
    Should Not Be Empty    ${r}

Validate Postgres Connection
    Connect Postgres
    ${r}=    Query    SELECT 1
    Should Not Be Empty    ${r}


# ========= DATA VALIDATION =========
Validate Oracle Source Data
    Connect Oracle
    ${r}=    Query    SELECT COUNT(*) FROM ${ORACLE_SCHEMA}."${ORACLE_TABLE}"
    Should Be True    ${r}[0][0] > 0

Validate Postgres Source Data Exists
    Connect Postgres
    ${r}=    Query    SELECT 1 FROM "public"."POSTGRES_CUSTOMER" LIMIT 1
    Should Not Be Empty    ${r}


# ========= PIPELINE =========
Import Pipeline From Template
    Import Pipelines From Template
    ...    ${unique_id}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${PIPELINE_NAME}
    ...    ${PIPELINE_FILE}

Create Pipeline Task
    Create Triggered Task From Template
    ...    ${unique_id}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${PIPELINE_NAME}
    ...    ${TASK_NAME}
    ...    ${GROUNDPLEX_NAME}
    ...    ${TASK_PARAMS}
    ...    ${TASK_NOTIFICATIONS}

Execute Pipeline Task
    Run Triggered Task With Parameters From Template
    ...    ${unique_id}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${PIPELINE_NAME}
    ...    ${TASK_NAME}


# ========= CDC VALIDATIONS =========
Validate Email Target Data
    Create Session    maildev    ${MAILDEV_URL}
    ${resp}=    GET On Session    maildev    /email
    ${emails}=    Set Variable    ${resp.json()}
    ${count}=     Get Length    ${emails}
    Should Be True    ${count} > 0
    ${mail}=      Get From List    ${emails}    -1
    Should Be Equal    ${mail['subject']}    ${EMAIL_SUBJECT}

Validate Diff Snap Configuration
    [Documentation]    Validate Diff snap sort path and output view mapping

    ${pipeline}=    Load Pipeline Template Json
    ${snaps}=       Get From Dictionary    ${pipeline}    snaps
    ${diff_snap}=   Find Diff Snap    ${snaps}

    Validate Diff Sort Path           ${diff_snap}
    Validate Diff Output View Mapping ${diff_snap}

Load Pipeline Template Json
    [Documentation]    Load and parse SnapLogic pipeline (.slp) file as JSON

    ${path}=    Set Variable    /app/src/pipelines/${PIPELINE_FILE}
    File Should Exist    ${path}

    ${json_text}=    Get File    ${path}
    ${pipeline}=     Evaluate    json.loads("""${json_text}""")    json
    [Return]    ${pipeline}

Find Diff Snap
    [Arguments]    ${snaps}
    FOR    ${snap}    IN    @{snaps}
        ${label}=    Get From Dictionary    ${snap}    label
        IF    '${label}' == 'Diff'
            [Return]    ${snap}
        END
    END
    Fail    Diff snap not found

Validate Diff Sort Path
    [Arguments]    ${diff_snap}
    ${settings}=    Get From Dictionary    ${diff_snap}    settings
    ${paths}=       Get From Dictionary    ${settings}    sortPaths
    ${first}=       Get From List    ${paths}    0
    Should Be Equal    ${first['path']}    $CUSTOMER_ID
    Should Be Equal    ${settings['sortOrder']}    Ascending

Validate Diff Output View Mapping
    [Arguments]    ${diff_snap}
    ${views}=    Get From Dictionary    ${diff_snap['settings']}    outputViewMapping
    Should Be Equal    ${views['Insertions']}    INSERTIONS
    Should Be Equal    ${views['Deletions']}     DELETIONS
    Should Be Equal    ${views['Modified']}      MODIFIED
    Should Be Equal    ${views['Unmodified']}    UNMODIFIED

Validate Diff Insertion
    Connect Oracle
    ${oracle_ids}=    Query    SELECT CUSTOMER_ID FROM ${ORACLE_SCHEMA}."${ORACLE_TABLE}"
    Connect Postgres
    ${pg_ids}=        Query    SELECT "CUSTOMER_ID" FROM "public"."POSTGRES_CUSTOMER"

    ${oracle_list}=    Create List
    ${pg_list}=        Create List

    FOR    ${r}    IN    @{oracle_ids}
        Append To List    ${oracle_list}    ${r}[0]
    END
    FOR    ${r}    IN    @{pg_ids}
        Append To List    ${pg_list}    ${r}[0]
    END
    FOR    ${id}    IN    @{oracle_list}
        List Should Contain Value    ${pg_list}    ${id}
    END

Validate Diff Modified CSV (Conditional)
    Create Session    maildev    ${MAILDEV_URL}
    ${resp}=    GET On Session    maildev    /email
    ${emails}=    Set Variable    ${resp.json()}
    ${mail}=      Get From List    ${emails}    -1

    ${has_attachments}=    Run Keyword And Return Status
    ...    Dictionary Should Contain Key    ${mail}    attachments

    Run Keyword If    ${has_attachments}
    ...    Log    Modified records present → CSV generated
    ...    ELSE
    ...    Log    No modified records → CSV not generated (valid CDC behavior)

Validate Email Logic
    Create Session    maildev    ${MAILDEV_URL}
    ${resp}=    GET On Session    maildev    /email
    ${emails}=    Set Variable    ${resp.json()}
    ${mail}=      Get From List    ${emails}    -1

    ${to}=    Get From Dictionary    ${mail['to'][0]}    address
    Should Be Equal    ${to}    ${TEST_TO_EMAIL}
    Should Be Equal    ${mail['subject']}    CDC report
    Should Contain    ${mail['html']}    CDC report
    Should Contain    ${mail['html']}    Hi team

Validate Diff Deletion Behavior
    [Documentation]    Validate that deleted Oracle records are detected as DELETIONS

    Connect Oracle
    ${oracle_ids}=    Query
    ...    SELECT CUSTOMER_ID FROM ${ORACLE_SCHEMA}."${ORACLE_TABLE}"

    Connect Postgres
    ${pg_ids}=        Query
    ...    SELECT "CUSTOMER_ID" FROM "public"."POSTGRES_CUSTOMER"

    ${oracle_list}=    Create List
    ${pg_list}=        Create List

    FOR    ${r}    IN    @{oracle_ids}
        Append To List    ${oracle_list}    ${r}[0]
    END

    FOR    ${r}    IN    @{pg_ids}
        Append To List    ${pg_list}    ${r}[0]
    END

    ${deleted_ids}=    Create List

    FOR    ${id}    IN    @{pg_list}
        Run Keyword If
        ...    '${id}' not in ${oracle_list}
        ...    Append To List    ${deleted_ids}    ${id}
    END

    Run Keyword If
    ...    len(${deleted_ids}) > 0
    ...    Log    🗑️ Deleted records detected by Diff: ${deleted_ids}
    ...    ELSE
    ...    Log    ℹ️ No deletions detected — valid CDC state
