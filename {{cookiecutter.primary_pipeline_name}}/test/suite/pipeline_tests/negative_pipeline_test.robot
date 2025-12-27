*** Settings ***
Documentation     Negative Scenario Tests for Sorting Pipeline
...               Verifies error handling for:
...               - Missing Input File
...               - Invalid CSV Format

Library           RequestsLibrary
Library           BuiltIn
Library           OperatingSystem
Resource          snaplogic_common_robot/snaplogic_apis_keywords/snaplogic_keywords.resource
Resource          ../../resources/files.resource
Resource          ../../resources/general.resource

Suite Setup       Initialize Variables

*** Variables ***
${pipeline_name}         AK_16sorting
${task_name}             NegativeSortingTask
${input_filename}        employeesA.csv

*** Test Cases ***
Missing Input File
    [Documentation]    Ensures pipeline fails when the input file is missing from the project space.
    [Tags]    negative_tests    missing_file
    
    # 1. Ensure file is removed from SnapLogic
    Log    Removing input file to simulate missing file scenario: ${PROJECT_SPACE}/shared/${input_filename}
    Delete File From Project    ${PROJECT_SPACE}/shared/${input_filename}
    
    # 2. Run Task and Expect Failure
    Log    Executing task: ${task_name} (Expecting Failure)
    
    # We use Run Keyword And Return Status to catch the failure
    ${status}    ${error_message}=    Run Keyword And Ignore Error    Run Triggered Task With Parameters From Template    ${unique_id}    ${PROJECT_SPACE}/shared    ${pipeline_name}    ${task_name}    &{EMPTY}
    
    Log    Task Execution Status: ${status}
    Log    Task Error Message: ${error_message}
    
    # Verification: The test passed if the task FAILED
    Should Be Equal    ${status}    FAIL    Expected task to fail due to missing input file, but it passed!

Invalid CSV Format
    [Documentation]    Ensures pipeline fails when input file has invalid CSV format (e.g. raw text).
    [Tags]    negative_tests    invalid_format
    
    # 1. Create a temporary bad file locally explicitly named 'employeesA.csv'
    # We do this in a temp directory so we don't overwrite the real data file
    ${temp_dir}=    Join Path    ${CURDIR}    temp_bad_data
    Create Directory    ${temp_dir}
    Create File    ${temp_dir}/${input_filename}    THIS IS NOT A CSV FILE\nGARBAGE DATA\nNO HEADERS HERE
    
    # 2. Upload the bad file to SnapLogic
    Log    Uploading invalid data file to: ${PROJECT_SPACE}/shared/${input_filename}
    Upload Files To SnapLogic From Template    ${temp_dir}    ${input_filename}    ${PROJECT_SPACE}/shared
    
    # 3. Run Task and Expect Failure
    Log    Executing task: ${task_name} with invalid data (Expecting Failure)
    ${status}    ${error_message}=    Run Keyword And Ignore Error    Run Triggered Task With Parameters From Template    ${unique_id}    ${PROJECT_SPACE}/shared    ${pipeline_name}    ${task_name}    &{EMPTY}
    
    Log    Task Execution Status: ${status}
    
    # Verification
    Should Be Equal    ${status}    FAIL    Expected task to fail due to invalid CSV format, but it passed!

    [Teardown]    Cleanup Temp Data    ${temp_dir}

*** Keywords ***
Initialize Variables
    ${unique_id}=    Get Unique Id
    Set Suite Variable    ${unique_id}

Delete File From Project
    [Arguments]    ${file_path}
    [Documentation]    Deletes a file from the SnapLogic file system using Basic Auth.
    ${auth}=    Create List    ${ORG_ADMIN_USER}    ${ORG_ADMIN_PASSWORD}
    Create Session    snap_api    ${URL}    auth=${auth}
    
    # SnapLogic API to delete file: DELETE /api/1/rest/slfs/<org>/<path>
    ${endpoint}=    Set Variable    /api/1/rest/slfs/${ORG_NAME}/${file_path}
    Log    Deleting file at: ${endpoint}
    
    ${response}=    DELETE On Session    snap_api    ${endpoint}
    
    # 204 No Content is typical for successful delete, or 200. 
    # If file doesn't exist, it might return 404, which is also fine for our purpose (file is gone).
    Log    Delete Response Code: ${response.status_code}

Cleanup Temp Data
    [Arguments]    ${dir_path}
    Remove Directory    ${dir_path}    recursive=True
