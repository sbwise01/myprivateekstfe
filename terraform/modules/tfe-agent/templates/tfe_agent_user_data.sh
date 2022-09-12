#!/usr/bin/env bash

install_docker() {
    echo "[INFO] Installing Docker for Amazon Linux 2."
    yum install docker -y
    systemctl enable --now docker.service
}

run_agent() {
    echo "[INFO] Downloading and running TFE agent."
    docker pull hashicorp/tfc-agent:latest
    docker run -e TFC_ADDRESS="${tfc_address}" -e TFC_AGENT_TOKEN="${tfc_agent_token}" -e TFC_AGENT_NAME="${tfc_agent_name}" hashicorp/tfc-agent
}

install_docker
run_agent