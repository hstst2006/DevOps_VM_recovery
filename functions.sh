#! /usr/bin/env bash

VERBOSE=0
MTU=1442
URL="YOUR EXTERNAL GITLABS URL HERE (or IP-address)"
DOCKERCOMPOSEVERSION="v2.2.3"

# Logs all arguments of this function if $VERBOSE is set to 1 with current time in green
log () {
    if [[ $VERBOSE -eq 1 ]]; then
        echo -e "\033[0;32m$(date "+%T")\033[0m" "$@"
    fi
}

# Check which options have been passed to the script
setOptions () {
    # Check if the option -v was passed with the script, set verbose to 1 if yes
    while getopts "v" opts; do
        case $opts in
            v)
            # Enables verbose mode
            VERBOSE=1
            log "Verbose mode is on!"
            ;;
            *)
            ;;
        esac
    done
}

# Creates a daemon.json config file for docker in /etc/docker/
setupDaemon () {
log "Creating daemon.json in /etc/docker/"
log "Setting MTU to $MTU"
cat << EOF > /etc/docker/daemon.json
{
    "mtu": $MTU
}
EOF
}

# Installs docker and dependencies using the official docker guide at https://docs.docker.com/engine/install/ubuntu/
# We assume this is an empty OS
installDocker() {
    # Setup docker repository
    log "Installing dependencies"
    apt-get update
    apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
    # Add docker official GPG key
    log "Adding docker official GPG key"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    # Set up stable repository
    log "Setting up stable repository"
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    # Install docker
    log "Installing docker"
    apt-get update
    apt-get install docker-ce docker-ce-cli containerd.io
    # Setup daemon.json
    setupDaemon
    # Restart the docker service after setting up daemon.json
    log "Restarting docker with new config file"
    systemctl restart docker
}

# Install docker compose
installCompose () {
    # Download the current stable release of Docker Compose
    # uname -s and -m appends our kernel and machine info so we get the right distribution
    log "Downloading the current stable release of Docker compose"
    curl -L "https://github.com/docker/compose/releases/download/$DOCKERCOMPOSEVERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

    # Apply executable permissions to the binary
    log "Applying executable permissions to the binary"
    chmod +x /usr/local/bin/docker-compose
}

# Create docker-compose.yaml
dockerCompose () {
log "Creating docker-compose.yaml in ~/gitlab"
cat << EOF > /home/$(whoami)/gitlab/docker-compose.yaml
version: '3.6'
services:
  web:
    image: 'gitlab/gitlab-ce:latest'
    restart: always
    hostname: 'gruppe19.gitlab.com'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url '$URL'
        gitlab_rails['gitlab_shell_ssh_port'] = 2222
    ports:
      - '80:80'
      - '443:443'
      - '2222:22'
    volumes:
      - '$GITLAB_HOME/config:/etc/gitlab'
      - '$GITLAB_HOME/logs:/var/log/gitlab'
      - '$GITLAB_HOME/data:/var/opt/gitlab'
    shm_size: '256m'
EOF
}

# Start gitlab in a detatched container using docker compose
installGitLab() {
    log "Installing Gitlab"
    # Add gitlab home directory variable to .bashrc
    log "Adding variables to /home/$(whoami)/.bashrc"
    echo "export GITLAB_HOME=/srv/gitlab" >> /home/$(whoami)/.bashrc
    log "Reimporting variables from /home/$(whoami)/.bashrc"
    source /home/$(whoami)/.bashrc

    # Make a folder in home to hold the docker-compose file for gitlab
    mkdir /home/$(whoami)/gitlab && cd /home/$(whoami)/gitlab
    dockerCompose

    log "Starting gitlab in a detatched contaner"
    docker-compose up -d

    # log "Root user password stored in /home/$(whoami)/gitlab/password"
    # touch /home/$(whoami)/gitlab/password
    # docker exec -it gitlab-web-1 grep 'Password:' /etc/gitlab/initial_root_password > /home/$(whoami)/gitlab/password
}