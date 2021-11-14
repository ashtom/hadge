#!/bin/bash

cat << "EOF"
.__                 .___  ____           
|  |__  _____     __| _/ / ___\   ____   
|  |  \ \__  \   / __ | / /_/  >_/ __ \  
|   Y  \ / __ \_/ /_/ | \___  / \  ___/  
|___|  /(____  /\____ |/_____/   \___  > 
     \/      \/      \/              \/  
                                         

EOF

echo This script will create a DeveloperSettings.xcconfig and Secrets.xcconfig file.
echo 
echo We need to ask a few questions first.
echo 
read -p "Press enter to get started."


# Get the user's Developer Team ID
echo 1. What is your Developer Team ID? You can get this from developer.apple.com.
read devTeamID

# Get the user's Org Identifier
echo 2. What is your organisation identifier? e.g. com.developername
read devOrgName

# Get the user's Developer Team ID
echo 1. What is your GitHub App Client ID? See README for how to create a GitHub OAuth App
read githubClientId

# Get the user's Org Identifier
echo 2. What is your GitHub App Client Secret? See README for how to create a GitHub OAuth App
read githubClientSecret

echo Creating DeveloperSettings.xcconfig

cat <<file >> DeveloperSettings.xcconfig
CODE_SIGN_IDENTITY = Apple Development
DEVELOPMENT_TEAM = $devTeamID
CODE_SIGN_STYLE = Automatic
ORGANIZATION_IDENTIFIER = $devOrgName
file

echo Creating Secrets.xcconfig

cat <<file >> Hadge/Secrets.xcconfig
GITHUB_CLIENT_ID = $githubClientId
GITHUB_CLIENT_SECRET = $githubClientSecret
file

echo Done! 
