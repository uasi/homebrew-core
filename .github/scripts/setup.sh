#!/bin/bash
set -xeo pipefail

RUNNER_NAME=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/RUNNER_NAME -H "Metadata-Flavor: Google")
VM_TOKEN=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/VM_TOKEN -H "Metadata-Flavor: Google")

# Initial setup: setup docker and github actions runner.
# This is done only once, if the machine is stopped/started, this block of code is not executed again.
if [ ! -d "/home/actions" ]; then
    # Setup docker
    apt-get -y update && apt-get install -y curl apt-transport-https ca-certificates software-properties-common jq wget

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    apt-get update

    apt-get install -y docker-ce

    useradd -m actions

    # Add user to docker group and restart docker to make group take effect
    usermod -aG docker actions
    newgrp docker
    systemctl restart docker

    su -c "curl -o install_runner.sh https://raw.githubusercontent.com/Homebrew/actions/master/create-gcloud-instance/install_runner.sh" actions
    su -c "curl -o config_runner.sh https://raw.githubusercontent.com/Homebrew/actions/master/create-gcloud-instance/config_runner.sh" actions

    # This needs to be run with the actions user:
    su -c "./install_runner.sh" actions

    # This needs to be run as root:
    source /home/actions/actions-runner/bin/installdependencies.sh

    # This needs to be run with the actions user:
    RUNNER_NAME=$RUNNER_NAME VM_TOKEN=$VM_TOKEN su -c "./config_runner.sh" actions
fi

su -c "curl -o start_runner.sh https://raw.githubusercontent.com/Homebrew/actions/master/create-gcloud-instance/start_runner.sh" actions

su -p -c "./start_runner.sh" actions
