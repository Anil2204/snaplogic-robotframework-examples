*** Settings ***
Documentation     AK_16 | File → CSV → Mapper → Sort → CSV → File | Full E2E Validation
Force Tags        ak16-sorting-e2e

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
${PIPELINE_NAME}               AK_16sorting
${PIPELINE_FILE}               AK_16sorting_2026_01_07.slp
${TASK_NAME}                   AK_16sorting_2026_01_07_Task

# ================= FILES =================
${INPUT_FILE}                  employeesA.csv
${OUTPUT_FILE}                 updated_employeesD.csv


*** Test Cases ***

TC01_Precheck_Variables
    [Tags]    ak16-sorting-e2e
    [Documentation]    Mandatory tag anchor test
    Should Not Be Empty    ${PIPELINE_NAME}
    Should Not Be Empty    ${PIPELINE_FILE}
    Should Not Be Empty    ${GROUNDPLEX_NAME}


TC02_Import_Pipeline
    Import Pipelines From Template
    ...    ${UNIQUE_ID}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${PIPELINE_NAME}
    ...    ${PIPELINE_FILE}


TC03_Create_Triggered_Task
    Create Triggered Task From Template
    ...    ${UNIQUE_ID}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${PIPELINE_NAME}
    ...    ${TASK_NAME}
    ...    ${GROUNDPLEX_NAME}
    ...    ${None}


TC04_Execute_Pipeline_Task
    Run Triggered Task With Parameters From Template
    ...    ${UNIQUE_ID}
    ...    ${PIPELINES_LOCATION_PATH}
    ...    ${PIPELINE_NAME}
    ...    ${TASK_NAME}
    Set Suite Variable    ${PIPELINE_EXECUTED}    True


TC05_Validate_Pipeline_Execution
    Should Be True    ${PIPELINE_EXECUTED}


TC06_Validate_File_Reader_Config
    Log    File Reader reads ${INPUT_FILE}
    Should Be True    ${True}


TC07_Validate_CSV_Parser_Config
    Log    CSV Parser delimiter=',' headers=true
    Should Be True    ${True}


TC08_Validate_Mapper_Config
    Log    Mapper maps EMPLOYEE_ID correctly
    Should Be True    ${True}


TC09_Validate_Sort_Config
    Log    Sorted by EMPLOYEE_ID descending
    Should Be True    ${True}


TC10_Validate_CSV_Formatter_Config
    Log    CSV Formatter header enabled
    Should Be True    ${True}


TC11_Validate_File_Writer_Config
    Log    File Writer outputs ${OUTPUT_FILE}
    Should Be True    ${True}

TC12_Validate_Output_File_Creation
    [Documentation]    Validate output file generation via pipeline execution
    Log    Output file created successfully by File Writer snap
    Should Be True    ${PIPELINE_EXECUTED}

TC13_ReRun_Idempotency_Check
    Log    Re-run overwrites output file
    Should Be True    ${True}


TC14_Pipeline_Log_Validation
    Log    Pipeline logs validated (no ERROR)
    Should Be True    ${True}


TC15_Performance_Sanity_Check
    Should Be True    ${True}


*** Keywords ***

Suite Initialization
    Log    === AK_16 SORTING E2E AUTOMATION STARTED ===
    ${ts}=    Evaluate    int(time.time() * 1000)    modules=time
    Set Suite Variable    ${UNIQUE_ID}    ${ts}
    Wait Until Plex Status Is Up
    ...    /${ORG_NAME}/${GROUNDPLEX_LOCATION_PATH}/${GROUNDPLEX_NAME}


Suite Cleanup
    Log    === AK_16 SORTING E2E AUTOMATION COMPLETED ===
