import os

env_content = """URL=https://elastic.snaplogic.com/
ORG_ADMIN_USER=pravula@snaplogic.com
ORG_ADMIN_PASSWORD=Daksha@123
ORG_NAME=SL-CATRobotPOC
PROJECT_SPACE=Priyanka_ProjectSpaceN
PROJECT_NAME=Priyanka_TestN
PIPELINES_LOCATION_PATH=Priyanka_ProjectSpaceN/shared
GROUNDPLEX_NAME=sl-gplex-priyanka-testN
GROUNDPLEX_ENV=sl-gplex-priyanka-testN
GROUNDPLEX_LOCATION_PATH=Priyanka_ProjectSpaceN/shared
RELEASE_BUILD_VERSION=main-37094
ACCOUNT_LOCATION_PATH=Priyanka_ProjectSpaceN/shared
SNAP_PLEX_LOCATION=Priyanka_ProjectSpaceN/shared
"""

file_path = os.path.join(os.getcwd(), '.env')
print(f"Writing clean UTF-8 .env file to: {file_path}")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(env_content)

print("Successfully wrote .env file.")
