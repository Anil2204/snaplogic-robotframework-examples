*** Settings ***
Documentation     Full SnapLogic Pipeline Execution Test
Library           RequestsLibrary
Library           BuiltIn
Library           OperatingSystem
Library           Collections
Resource          snaplogic_common_robot/snaplogic_apis_keywords/snaplogic_keywords.resource
Resource          ../../resources/files.resource
Resource          ../../resources/general.resource

Suite Setup       Initialize Variables

*** Variables ***
${pipeline_name}         AK_17Count_the_no_of_records
${pipeline_name_slp}     AK_17Count_the_no_of_records_2025_12_08.slp
${task_name}             CountRecordsTask
${input_filename}        employeesA.csv
${output_filename}       employee_id_count.csv

*** Test Cases ***
Upload Input File
    [Documentation]    Uploads the input CSV file to the SnapLogic project space.
    [Tags]    basic_pipeline    upload
    ${file_dir}=    Join Path    ${CURDIR}    ../../data
    # Using the template keyword found in oracle.robot
    # Arguments: source_dir, file_name, destination_path
    Upload Files To SnapLogic From Template    ${file_dir}    ${input_filename}    ${PROJECT_SPACE}/shared

Import Pipeline
    [Documentation]    Imports the pipeline into the project space.
    [Tags]    basic_pipeline
    # Arguments: unique_id, path, pipeline_name, pipeline_file
    Import Pipelines From Template    ${unique_id}    ${PROJECT_SPACE}/shared    ${pipeline_name}    ${pipeline_name_slp}

Create Triggered Task
    [Documentation]    Creates a triggered task for the pipeline.
    [Tags]    basic_pipeline
    # Arguments: unique_id, path, pipeline_name, task_name, plex, params, notifications
    # Passed &{EMPTY} for params and notifications to ensure dictionary type
    Create Triggered Task From Template    ${unique_id}    ${PROJECT_SPACE}/shared    ${pipeline_name}    ${task_name}    ${GROUNDPLEX_NAME}    &{EMPTY}    &{EMPTY}

Execute Triggered Task
    [Documentation]    Executes the triggered task and waits for completion.
    [Tags]    basic_pipeline
    # Arguments: unique_id, path, pipeline_name, task_name, params (required dictionary/args)
    # Passed &{EMPTY} as the 5th argument for params
    Run Triggered Task With Parameters From Template    ${unique_id}    ${PROJECT_SPACE}/shared    ${pipeline_name}    ${task_name}    &{EMPTY}

Verify Mapper and Aggregate Logic
    [Documentation]    Verifies that the output file content matches the expected logic (Mapper: employeeID, Aggregate: count=11).
    [Tags]    basic_pipeline    verify    mapper    aggregate
    
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

    # 3. Verify Mapper Logic (Renaming: EMPLOYEE_ID -> employeeID)
    Should Contain    ${content}    "employeeID"    Mapper failed: Header 'employeeID' not found in output.

    # 4. Verify Aggregate Logic (Count: 11 rows -> 11)
    # Note: Output might be quoted like "11" or just 11. Checking for 11 ensures the count is correct.
    Should Contain    ${content}    11    Aggregate failed: Expected count '11' not found in output.

*** Keywords ***
Initialize Variables
    ${unique_id}=    Get Unique Id
    Set Suite Variable    ${unique_id}

Download File From Project
    [Arguments]    ${file_path}
    [Documentation]    Downloads a file from the SnapLogic file system using the REST API.
    ...    Arguments:
    ...        ${file_path}: The path to the file relative to the project (e.g., project_space/shared/filename.csv)
    
    ${auth}=    Create List    ${ORG_ADMIN_USER}    ${ORG_ADMIN_PASSWORD}
    Create Session    snap_download_basic    ${URL}    auth=${auth}
    ${response}=    GET On Session    snap_download_basic    /api/1/rest/slfs/${ORG_NAME}/${file_path}
    Should Be Equal As Integers    ${response.status_code}    200
    [Return]    ${response.content.decode('utf-8')}
