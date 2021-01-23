#!/bin/bash

# This is a script that can be run on a freshly setup server (see the README
# for more details) and bring it up to a production-ready state.  This script
# requires sudo privileges to work and it should already be scaffolded using
# bin/scaffold.sh

set -exuo pipefail
IFS=$'\n\t'

# Setup server
sudo hostnamectl set-hostname "albertyw.com"

# Clone repository
cd ~
git clone "git@github.com:albertyw/albertyw.com"

# Install nginx
sudo add-apt-repository ppa:nginx/stable
sudo apt-get update
sudo apt-get install -y nginx

# Configure nginx
sudo rm /etc/nginx/nginx.conf
sudo rm -rf /etc/nginx/sites-available
sudo rm -rf /etc/nginx/sites-enabled/*
sudo ln -s ~/albertyw.com/config/nginx/nginx.conf /etc/nginx/nginx.conf
sudo ln -s ~/albertyw.com/config/nginx/app /etc/nginx/sites-enabled/albertyw.com-app
sudo ln -s ~/albertyw.com/config/nginx/headers /etc/nginx/sites-enabled/albertyw.com-headers
sudo rm -rf /var/www/html

# Secure nginx
sudo mkdir -p /etc/nginx/ssl
curl https://ssl-config.mozilla.org/ffdhe2048.txt | sudo tee /etc/nginx/ssl/dhparams.pem > /dev/null
# Copy server.key and server.pem to /etc/nginx/ssl.  The private/public key
# pair can be generated from Cloudflare or letsencrypt.
sudo service nginx restart

# Setup up docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce
sudo usermod -aG docker "${USER}"

# Set up directory structures
ln -s .env.production .env
