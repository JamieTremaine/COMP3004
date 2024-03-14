#!/bin/bash

while getopts h:p:t:m: flag
do
    case "${flag}" in
        h) HOSTNAME=${OPTARG};;
        p) PASSWORD=${OPTARG};;
        t) TOKEN=${OPTARG};;
        m) MASTER=${OPTARG};;
    esac
done

echo "STARTING ADDING DOCKER"
sshpass -p $PASSWORD ssh -oStrictHostKeyChecking=no -i ~/.ssh/id_rsa $HOSTNAME << EOF

export TOKEN="$TOKEN"
export MASTER="$MASTER"

if ! command -v docker &> /dev/null; then
    echo "Docker is not installed on machine: $HOSTNAME"
    echo "installing docker..."

    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "docker installed"
fi

SWARM_STATUS=$(docker info --format '{{.Swarm.LocalNodeState}}')

if [ "\$SWARM_STATUS" == "active" ]; then
    docker swarm leave --force
fi

docker swarm join --token \$TOKEN \$MASTER

EOF

echo "FINSIHED ADDING DOCKER"

exit 0