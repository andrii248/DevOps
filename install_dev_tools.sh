#!/usr/bin/env bash
set -e

echo "Оновлення списку пакетів..."
sudo apt update

install_docker() {
  if docker --version >/dev/null 2>&1; then
    echo "Docker вже встановлений: $(docker --version)"
  else
    echo "Встановлення Docker..."
    sudo apt install -y docker.io

    if command -v systemctl >/dev/null 2>&1; then
      sudo systemctl enable docker || true
      sudo systemctl start docker || true
    fi

    if docker --version >/dev/null 2>&1; then
      echo "Docker встановлено: $(docker --version)"
    else
      echo "Docker не вдалося повністю активувати. Якщо ти у WSL, увімкни Docker Desktop WSL Integration."
    fi
  fi
}

install_docker_compose() {
  if docker compose version >/dev/null 2>&1; then
    echo "Docker Compose вже встановлений: $(docker compose version)"
  elif command -v docker-compose >/dev/null 2>&1; then
    echo "Docker Compose вже встановлений: $(docker-compose --version)"
  else
    echo "Встановлення Docker Compose..."
    sudo apt install -y docker-compose-plugin

    if docker compose version >/dev/null 2>&1; then
      echo "Docker Compose встановлено: $(docker compose version)"
    elif command -v docker-compose >/dev/null 2>&1; then
      echo "Docker Compose встановлено: $(docker-compose --version)"
    else
      echo "Не вдалося перевірити встановлення Docker Compose"
    fi
  fi
}

install_python() {
  if command -v python3 >/dev/null 2>&1; then
    echo "Python вже встановлений: $(python3 --version)"
  else
    echo "Встановлення Python..."
    sudo apt install -y python3 python3-pip python3-venv
    echo "Python встановлено: $(python3 --version)"
  fi

  if ! python3 -m pip --version >/dev/null 2>&1; then
    echo "Встановлення pip для Python..."
    sudo apt install -y python3-pip python3-venv
  fi
}

install_django() {
  if python3 -m pip show Django >/dev/null 2>&1; then
    echo "Django вже встановлений: $(python3 -m pip show Django | grep '^Version:' | awk '{print $2}')"
  else
    echo "Встановлення Django..."
    python3 -m pip install --user --break-system-packages Django
    echo "Django встановлено: $(python3 -m django --version)"
  fi
}

install_docker
install_docker_compose
install_python
install_django

echo "Усі необхідні інструменти встановлені або вже були наявні."
