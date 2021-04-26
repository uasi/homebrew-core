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

    cat > install_runner.sh <<'endmsg'
#!/bin/bash
set -x

mkdir -p /home/actions/actions-runner
curl https://api.github.com/repos/actions/runner/releases/latest |
  egrep -o 'https://github.com/actions/runner/releases/download/v[0-9.]+/actions-runner-linux-x64-[0-9.]+\.tar\.gz' |
  uniq |
  xargs curl -L |
  tar xzv -C /home/actions/actions-runner
endmsg

  # This needs to be run with the actions user:
  chmod +x install_runner.sh
  su -c "./install_runner.sh" actions

  # This needs to be run as root:
  source /home/actions/actions-runner/bin/installdependencies.sh

    cat > config_runner.sh <<'endmsg'
#!/bin/bash
set -x

cd /home/actions/actions-runner
./config.sh \
  --url "https://github.com/Homebrew/homebrew-core" \
  --token "${VM_TOKEN}" \
  --name "${RUNNER_NAME}" \
  --labels ${RUNNER_NAME} \
  --replace \
  --unattended \
  --work _work
endmsg

    # This needs to be run with the actions user:
    chmod +x config_runner.sh
    RUNNER_NAME=$RUNNER_NAME VM_TOKEN=$VM_TOKEN su -c "./config_runner.sh" actions
fi

cat > start_runner.sh <<'endmsg'
#!/bin/bash
set -x

cd /home/actions/actions-runner
./bin/runsvc.sh
endmsg

chmod +x start_runner.sh

su -p -c "./start_runner.sh" actions
