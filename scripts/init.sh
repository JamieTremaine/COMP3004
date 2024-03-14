#!/bin/bash

while getopts p:u: flag
do
    case "${flag}" in
        u) USERNAME=${OPTARG};;
        p) PASSWORD=${OPTARG};;
       
    esac
done

#Remove any whitespace
USERNAME="${USERNAME#"${USERNAME%%[![:space:]]*}"}"
USERNAME="${USERNAME%"${USERNAME##*[![:space:]]}"}"

PASSWORD="${PASSWORD#"${PASSWORD%%[![:space:]]*}"}"
PASSWORD="${PASSWORD%"${PASSWORD##*[![:space:]]}"}"

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

if ! command -v docker &> /dev/null; then
    echo "Docker is not installed on this machine"
    echo "installing docker..."
    ./install-docker.sh
fi

sudo apt install -y sshpass

SWARM_STATUS=$(docker info --format '{{.Swarm.LocalNodeState}}')

if [ "$SWARM_STATUS" == "active" ]; then
    echo "Host is already in a swarm. Leaving..."
    docker swarm leave --force
fi

HOST_IP=$(hostname -I | awk '{print $1}')

docker swarm init --advertise-addr $HOST_IP | echo "Created swarm"

TOKEN=$(docker swarm join-token worker | awk '/token/ {print $5}')
ADDR=$(docker swarm join-token worker | grep -Eo '[0-9]+.[0-9]+.[0-9]+.[0-9]+:[0-9]+')

while IFS= read -r line || [[ -n "$line" ]]; do
    HOST=$(echo "$line" | awk -F'=' '{print $2}' | awk -F' ' '{print $1}')
    MACHINE_PASSWORD=$(echo "$line" | awk -F'=' '{print $3}')

    ./add.sh -h $HOST -p $MACHINE_PASSWORD -t $TOKEN -m $ADDR
done < hosts.txt

docker login --username "$USERNAME" --password "$PASSWORD"
docker stack deploy --with-registry-auth -c ../docker-compose.yml COMP3004

exit 0