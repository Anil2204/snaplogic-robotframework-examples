*** Settings ***
Documentation       Comprehensive Pipeline Execution Test Suite
...                 Styled exactly like the Snowflake Database Integration Test Suite.
...                 This suite covers:
...                 • Uploading test input files
...                 • Importing the pipeline
...                 • Creating triggered task
...                 • Executing triggered task
...                 • Verifying output in SnapLogic project space
...
...                 📚 Follows structure described in:
...                 README/How To Guides/test_documentation_guides/generic_test_case_documentation_template.md

Library             Collections
Library             OperatingSystem

Resource            snaplogic_common_robot/snaplogic_apis_keywords/snaplogic_keywords.resource
Resource            ../../resources/files.resource
Resource            ../../resources/general.resource

Suite Setup         Initialize Environment
Suite Teardown      Cleanup Imported Pipeline And Task


*** Variables ***
${PROJECT_PATH}                 Priyanka_ProjectSpaceN/shared
${PIPELINE_NAME}                AK_16sorting
${PIPELINE_FILE}                AK_16sorting_2025_12_09.slp
${TASK_NAME}                    SortingTask

${INPUT_FILE}                   employeesA.csv
${OUTPUT_FILE}                  updated_employeesD.csv


*** Test Cases ***

Upload Pipeline Input Files
    [Documentation]    Uploads required test input CSV files into SnapLogic project space.
    ...                Uses standardized upload template.
    [Tags]    final_suite
    [Template]    Upload File Using File Protocol Template
    ${CURDIR}/../../data/${INPUT_FILE}    ${PROJECT_PATH}

Import Sorting Pipeline
    [Documentation]    Imports the sorting pipeline .slp file into SnapLogic project space.
    ...                Pipeline will be identified by ${PIPELINE_NAME}.
    [Tags]    final_suite
    [Template]    Import Pipelines From Template
    ${unique_id}    ${PROJECT_PATH}    ${PIPELINE_NAME}    ${PIPELINE_FILE}

Create Triggered Task
    [Documentation]    Creates a triggered task that executes the sorting pipeline.
    ...                The task is named: ${TASK_NAME}
    [Tags]    final_suite
    [Template]    Create Triggered Task From Template
    ${unique_id}    ${PROJECT_PATH}    ${PIPELINE_NAME}    ${TASK_NAME}    ${GROUNDPLEX_NAME}

Execute Sorting Task
    [Documentation]    Executes the previously created triggered task.
    ...                Validates that execution completes successfully.
    [Tags]    final_suite
    [Template]    Run Triggered Task With Parameters From Template
    ${unique_id}    ${PROJECT_PATH}    ${PIPELINE_NAME}    ${TASK_NAME}

Verify Output File Exists
    [Documentation]    Verifies that the transformed CSV output file exists in the project space.
    [Tags]    final_suite
    Verify File Exists In Project Space    ${PROJECT_PATH}    ${OUTPUT_FILE}

Verify Output Sorting Rules
    [Documentation]    Downloads and validates sorted output.
    [Tags]    final_suite
    ${content}=    Download File From Project    ${PROJECT_PATH}/${OUTPUT_FILE}
    # Verify Sorting (Descending) - 110 should appear before 100
    ${index_110}=    Evaluate    $content.find('110')
    ${index_100}=    Evaluate    $content.find('100')
    Should Be True    ${index_110} > -1    Value 110 missing
    Should Be True    ${index_100} > -1    Value 100 missing
    Should Be True    ${index_110} < ${index_100}    Sorting failed: Expected 110 to appear before 100

Verify Mapper Logic
    [Documentation]    Verifies that the Mapper snap correctly preserved the data schema.
    [Tags]    final_suite
    ${content}=    Download File From Project    ${PROJECT_PATH}/${OUTPUT_FILE}
    # Verify Pass-Through of other columns
    Should Contain    ${content}    FIRST_NAME
    Should Contain    ${content}    LAST_NAME
    Should Contain    ${content}    Steven
    Should Contain    ${content}    King


*** Keywords ***
Initialize Environment
    [Documentation]    Initial test setup — loads environment and generates unique ID
    # Load All Env Files - Removed as it is handled by Suite Setup or not available
    ${unique_id}=    Get Unique Id
    Set Suite Variable    ${unique_id}

Verify File Exists In Project Space
    [Arguments]    ${project_folder}    ${filename}
    ${entries}=    Get Project List    ${ORG_NAME}    ${project_folder}
    ${found}=      Set Variable    ${FALSE}
    FOR    ${item}    IN    @{entries}
        IF    '${item}[name]' == '${filename}'
            ${found}=    Set Variable    ${TRUE}
            BREAK
        END
    END
    Should Be True    ${found}

Download File From Project
    [Arguments]    ${file_path}
    ${auth}=    Create List    ${ORG_ADMIN_USER}    ${ORG_ADMIN_PASSWORD}
    Create Session    snap_download    ${URL}    auth=${auth}
    ${response}=    GET On Session    snap_download    /api/1/rest/slfs/${ORG_NAME}/${file_path}
    Should Be Equal As Integers    ${response.status_code}    200
    RETURN    ${response.content.decode('utf-8')}

Cleanup Imported Pipeline And Task
   Run Keyword And Ignore Error    Delete Triggered Task    ${unique_id}    ${PIPELINE_NAME}    ${TASK_NAME}
  Run Keyword And Ignore Error    Delete Pipeline          ${unique_id}    ${PIPELINE_NAME}
