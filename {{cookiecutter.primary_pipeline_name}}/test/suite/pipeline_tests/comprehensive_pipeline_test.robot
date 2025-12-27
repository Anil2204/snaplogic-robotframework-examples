*** Settings ***
Documentation     Comprehensive Pipeline Test for Sorting Pipeline
...               Verifies the end-to-end flow: File Reader -> CSV Parser -> Mapper -> Sort -> CSV Formatter -> File Writer.
...               Based on provided screenshots:
...               - Input: employeesA.csv
...               - Sort: EMPLOYEE_ID (descending)
...               - Output: updated_employeesD.csv (with headers)

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
${task_name}             ComprehensiveSortingTask
${input_filename}        employeesA.csv
${output_filename}       updated_employeesD.csv

*** Test Cases ***
Upload Test Data
    [Documentation]    Uploads the input CSV file (employeesA.csv) to the SnapLogic project space.
    [Tags]    comprehensive_pipeline    upload
    ${file_dir}=    Join Path    ${CURDIR}    ../../data
    Log    Uploading input file from ${file_dir}/${input_filename}
    Upload Files To SnapLogic From Template    ${file_dir}    ${input_filename}    ${PROJECT_SPACE}/shared

Import Pipeline
    [Documentation]    Imports the sorting pipeline from the SLP file.
    [Tags]    comprehensive_pipeline    import
    Log    Importing pipeline: ${pipeline_name}
    Import Pipelines From Template    ${unique_id}    ${PROJECT_SPACE}/shared    ${pipeline_name}    ${pipeline_name_slp}

Create Triggered Task
    [Documentation]    Creates a triggered task for the sorting pipeline in the specified Groundplex.
    [Tags]    comprehensive_pipeline    create_task
    Log    Creating task: ${task_name} on Groundplex: ${GROUNDPLEX_NAME}
    Create Triggered Task From Template    ${unique_id}    ${PROJECT_SPACE}/shared    ${pipeline_name}    ${task_name}    ${GROUNDPLEX_NAME}    &{EMPTY}    &{EMPTY}

Execute Triggered Task
    [Documentation]    Executes the triggered task and waits for completion.
    [Tags]    comprehensive_pipeline    execute
    Log    Executing task: ${task_name}
    Run Triggered Task With Parameters From Template    ${unique_id}    ${PROJECT_SPACE}/shared    ${pipeline_name}    ${task_name}    &{EMPTY}

Verify Output File Existence
    [Documentation]    Verifies that the output file (updated_employeesD.csv) was created in the project space.
    [Tags]    comprehensive_pipeline    verify_file
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

Verify Output Content And Sorting
    [Documentation]    Downloads the output file and verifies:
    ...                1. It contains the expected CSV header.
    ...                2. Data is sorted by EMPLOYEE_ID in descending order.
    [Tags]    comprehensive_pipeline    verify_content
    
    # 1. Download content
    ${content}=    Download File From Project    ${PROJECT_SPACE}/shared/${output_filename}
    Log    Downloaded Content: ${content}

    # 2. Verify Headers (CSV Formatter 'Write CSV header' is checked)
    # Assuming standard CSV format, check for EMPLOYEE_ID in the first line
    ${lines}=    Split String    ${content}    \n
    ${header}=    Get From List    ${lines}    0
    Should Contain    ${header}    EMPLOYEE_ID    Header row missing or incorrect. Found: ${header}

    # 3. Verify Sorting (Descending)
    # We expect '110' to appear in the content before '100'
    ${index_110}=    Evaluate    $content.find('110')
    ${index_100}=    Evaluate    $content.find('100')
    
    Should Be True    ${index_110} > -1    Value '110' not found in output
    Should Be True    ${index_100} > -1    Value '100' not found in output
    
    # Validation Logic: For descending sort, 110 (larger ID) comes first (smaller index)
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
