#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== Starting Monitoring Stack (Prometheus & Grafana) Installation ==="

# 1. Update system and install prerequisites
echo "-> Updating system and installing prerequisites..."
apt update && apt install -y ca-certificates curl gnupg

# 2. Add Docker's official GPG key and APT repository for Debian/Ubuntu (if not already installed)
if ! command -v docker &> /dev/null; then
    echo "-> Setting up Docker repository..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    echo "-> Installing Docker Engine and Docker Compose..."
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    echo "-> Docker is already installed."
fi

# 3. Ensure external Docker volumes exist
echo "-> Verifying external volumes..."
docker volume inspect monitoring_prometheus-data >/dev/null 2>&1 || \
  (echo "-> Creating named volume: monitoring_prometheus-data" && docker volume create monitoring_prometheus-data)

docker volume inspect monitoring_grafana-data >/dev/null 2>&1 || \
  (echo "-> Creating named volume: monitoring_grafana-data" && docker volume create monitoring_grafana-data)

# 4. Launch Monitoring stack
echo "-> Starting Monitoring containers..."
docker compose up -d

echo "=== Installation Complete! ==="
echo "Grafana is running at: http://$(hostname -I | awk '{print $1}'):3000 (Default login: admin / admin)"
echo "Prometheus is running at: http://$(hostname -I | awk '{print $1}'):9090"
