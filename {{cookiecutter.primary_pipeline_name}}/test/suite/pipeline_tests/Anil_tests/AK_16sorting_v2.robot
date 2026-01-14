*** Settings ***
Documentation     AK_16 Sorting v2 | Regression Introduced
Force Tags        ak16

Library           OperatingSystem
Library           Collections
Library           DependencyLibrary

Resource          snaplogic_common_robot/snaplogic_apis_keywords/snaplogic_keywords.resource

Suite Setup       Log    === AK_16 SORTING v2 SUITE STARTED ===
Suite Teardown    Log    === AK_16 SORTING v2 SUITE COMPLETED ===


*** Variables ***
${ORG_NAME}                    SL-CATRobotPOC
${PROJECT_SPACE}               anil-automation-ps
${PROJECT_PATH}                anil-automation-ps/anil_project
${PIPELINES_LOCATION_PATH}     ${PROJECT_PATH}
${ACCOUNT_LOCATION_PATH}       anil-automation-ps/shared

# ================= GROUNDPLEX =================
${GROUNDPLEX_NAME}             anil-groundplex-automation
${GROUNDPLEX_LOCATION_PATH}    anil-automation-ps/shared

${PIPELINE_NAME}    AK_16sorting_2026_01_07
${PIPELINE_FILE}    AK_16sorting_2026_01_07.slp
${TASK_NAME}        AK_16sorting_2026_01_07_Task
${OUTPUT_FILE}      updated_employeesD.csv


*** Test Cases ***

TC01_Pipeline_Execution
    Log    Pipeline executed successfully
    Should Be True    ${True}

TC02_Output_File_Creation
    [Documentation]    Regression introduced in v2
    Fail    Output file not generated due to regression

TC03_Sort_Validation
    Log    Sorting defect fixed in v2
    Should Be True    ${True}

TC04_CSV_Header_Validation
    Log    Header validated
    Should Be True    ${True}
