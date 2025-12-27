*** Settings ***
Documentation     Sorting Pipeline Test for AK_16sorting
Library           RequestsLibrary
Library           BuiltIn
Library           OperatingSystem
Library           Collections
Library           String
Resource          snaplogic_common_robot/snaplogic_apis_keywords/snaplogic_keywords.resource
Resource          ../../resources/files.resource
Resource          ../../resources/general.resource

Suite Setup       Initialize Variables

*** Variables ***
${pipeline_name}         AK_16sorting
${pipeline_name_slp}     AK_16sorting_2025_12_09.slp
${task_name}             SortingTask
${input_filename}        employeesA.csv
${output_filename}       updated_employeesD.csv

*** Test Cases ***
Upload Input File
    [Documentation]    Uploads the input CSV file to the SnapLogic project space.
    [Tags]    sorting_pipeline    upload
    ${file_dir}=    Join Path    ${CURDIR}    ../../data
    # Reusing employeesA.csv which contains IDs 100-110
    Upload Files To SnapLogic From Template    ${file_dir}    ${input_filename}    ${PROJECT_SPACE}/shared

Import Pipeline
    [Documentation]    Imports the sorting pipeline.
    [Tags]    sorting_pipeline
    Import Pipelines From Template    ${unique_id}    ${PROJECT_SPACE}/shared    ${pipeline_name}    ${pipeline_name_slp}

Create Triggered Task
    [Documentation]    Creates a triggered task for the sorting pipeline.
    [Tags]    sorting_pipeline
    Create Triggered Task From Template    ${unique_id}    ${PROJECT_SPACE}/shared    ${pipeline_name}    ${task_name}    ${GROUNDPLEX_NAME}    &{EMPTY}    &{EMPTY}

Execute Triggered Task
    [Documentation]    Executes the triggered task.
    [Tags]    sorting_pipeline
    Run Triggered Task With Parameters From Template    ${unique_id}    ${PROJECT_SPACE}/shared    ${pipeline_name}    ${task_name}    &{EMPTY}

Verify Sorted Output
    [Documentation]    Verifies that the output file is sorted in descending order.
    [Tags]    sorting_pipeline    verify
    
    # 1. Verify file existence
    Log    Checking for output file: ${output_filename}
    ${entries}=    Get Project List    ${ORG_NAME}    ${PROJECT_SPACE}/shared
    ${found}=    Set Variable    ${FALSE}
    
    FOR    ${entry}    IN    @{entries}
        IF    '${entry}[name]' == '${output_filename}'
            ${found}=    Set Variable    ${TRUE}
            Log    Found output file: ${output_filename}
            BREAK
        END
    END
    Should Be True    ${found}    Output file '${output_filename}' was not found in ${PROJECT_SPACE}/shared

    # 2. Download content
    ${content}=    Download File From Project    ${PROJECT_SPACE}/shared/${output_filename}
    Log    Downloaded Content: ${content}

    # 3. Verify Sorting (Descending)
    # 110 should appear before 100
    ${index_110}=    Evaluate    $content.find('110')
    ${index_100}=    Evaluate    $content.find('100')
    
    Should Be True    ${index_110} > -1    Value '110' not found in output
    Should Be True    ${index_100} > -1    Value '100' not found in output
    
    # Ensure 110 appears BEFORE 100 (smaller index)
    Should Be True    ${index_110} < ${index_100}    Sorting failed: 110 (index ${index_110}) should be before 100 (index ${index_100}) for descending sort.

*** Keywords ***
Initialize Variables
    ${unique_id}=    Get Unique Id
    Set Suite Variable    ${unique_id}

Download File From Project
    [Arguments]    ${file_path}
    [Documentation]    Downloads a file from the SnapLogic file system using Basic Auth.
    ${auth}=    Create List    ${ORG_ADMIN_USER}    ${ORG_ADMIN_PASSWORD}
    Create Session    snap_download    ${URL}    auth=${auth}
    ${response}=    GET On Session    snap_download    /api/1/rest/slfs/${ORG_NAME}/${file_path}
    Should Be Equal As Integers    ${response.status_code}    200
    RETURN    ${response.content.decode('utf-8')}
