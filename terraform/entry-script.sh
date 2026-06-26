#!/bin/bash
sudo dnf update -y && sudo dnf install -y docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user

# install docker-compose
sudo curl -SL "https://github.com/docker/compose/releases/download/v2.36.2/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose