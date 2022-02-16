#! /usr/bin/env bash

source functions.sh

# Parses -v for verbose mode
setOptions "$@"

# Install docker and docker compose
installDocker
installCompose

# Adds user to docker group
usermod -aG docker "$USER"

# Start gitlab in a detatched container
installGitLab

echo "Finished!"
echo "Add users in the gitrails console with: "
echo "docker exec -it gitlab_web_1 gitlab-rails console"