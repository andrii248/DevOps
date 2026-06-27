#!/usr/bin/env bash
set -e

PYTHON_VERSION="3.9"

echo "Оновлення списку пакетів..."
sudo apt update

install_docker() {
  if command -v docker >/dev/null 2>&1 && docker --version 2>/dev/null | grep -q "Docker version"; then
    echo "Docker вже встановлений: $(docker --version)"
  else
    echo "Встановлення Docker CE з офіційного репозиторію..."

    sudo apt install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings

    if [ ! -f /etc/apt/keyrings/docker.asc ]; then
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.asc
      sudo chmod a+r /etc/apt/keyrings/docker.asc
    fi

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Docker встановлено: $(docker --version)"
  fi
}

install_docker_compose() {
  if docker compose version >/dev/null 2>&1; then
    echo "Docker Compose вже встановлений: $(docker compose version)"
  else
    echo "Docker Compose встановлюється разом із docker-compose-plugin..."
    sudo apt update
    sudo apt install -y docker-compose-plugin
    echo "Docker Compose встановлено: $(docker compose version)"
  fi
}

install_python() {
  if command -v python${PYTHON_VERSION} >/dev/null 2>&1; then
    echo "Python ${PYTHON_VERSION} вже встановлений: $(python${PYTHON_VERSION} --version)"
  else
    echo "Встановлення Python ${PYTHON_VERSION}..."

    sudo apt install -y software-properties-common
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt update
    sudo apt install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-venv python${PYTHON_VERSION}-dev python3-pip

    echo "Python встановлено: $(python${PYTHON_VERSION} --version)"
  fi
}

install_django() {
  if pip3 show django >/dev/null 2>&1; then
    echo "Django вже встановлений: $(pip3 show django | grep '^Version:' | awk '{print $2}')"
  else
    echo "Встановлення Django через pip..."
    pip3 install --user django
    echo "Django встановлено: $(python3 -m django --version)"
  fi
}

install_docker
install_docker_compose
install_python
install_django

echo "Усі необхідні інструменти встановлені або вже були наявні."