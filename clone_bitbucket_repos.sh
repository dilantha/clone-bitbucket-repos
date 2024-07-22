#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 -d <destination_path>"
    exit 1
}

# Parse arguments
while getopts ":d:" opt; do
    case ${opt} in
        d )
            REPO_CLONE_PATH=$OPTARG
            ;;
        \? )
            usage
            ;;
    esac
done
shift $((OPTIND -1))

# Check if destination path is provided
if [ -z "$REPO_CLONE_PATH" ]; then
    usage
fi

# Ensure the destination path exists or create it
if [ ! -d "$REPO_CLONE_PATH" ]; then
    mkdir -p "$REPO_CLONE_PATH"
    if [ $? -ne 0 ]; then
        echo "Failed to create directory: $REPO_CLONE_PATH"
        exit 1
    fi
fi

# Use gum to ask for Bitbucket username, app password, and workspace
USERNAME=$(gum input --placeholder "Enter your Bitbucket username")
APP_PASSWORD=$(gum input --password --placeholder "Enter your Bitbucket app password")
WORKSPACE=$(gum input --placeholder "Enter your Bitbucket workspace")

# Fetch the list of repositories
BASE_URL="https://api.bitbucket.org/2.0/repositories/$WORKSPACE?pagelen=100"

# Function to fetch and clone repositories
fetch_and_clone() {
    URL=$1
    while [ -n "$URL" ]; do
        RESPONSE=$(curl -u $USERNAME:$APP_PASSWORD $URL)
        REPOS=$(echo $RESPONSE | jq -r '.values[] | .links.clone[1].href')
        for REPO in $REPOS; do
            git clone $REPO "$REPO_CLONE_PATH/$(basename $REPO .git)"
        done
        URL=$(echo $RESPONSE | jq -r '.next')
    done
}

# Start fetching and cloning
fetch_and_clone $BASE_URL
