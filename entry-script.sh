#!/bin/bash
sudo dnf update -y && sudo dnf install -y docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
docker run -p 8080:80 nginx
