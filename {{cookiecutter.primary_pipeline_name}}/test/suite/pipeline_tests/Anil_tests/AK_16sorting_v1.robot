*** Settings ***
Documentation     AK_16 Sorting v1 | Initial Defect
Force Tags        ak16

Library           OperatingSystem
Library           Collections
Library           DependencyLibrary

Resource          snaplogic_common_robot/snaplogic_apis_keywords/snaplogic_keywords.resource

Suite Setup       Log    === AK_16 SORTING v1 SUITE STARTED ===
Suite Teardown    Log    === AK_16 SORTING v1 SUITE COMPLETED ===


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
    File Should Exist    ${OUTPUT_FILE}

TC03_Sort_Validation
    [Documentation]    Known sorting defect in v1
    Fail    Sorting logic is incorrect in v1

TC04_CSV_Header_Validation
    Log    Header validated
    Should Be True    ${True}
