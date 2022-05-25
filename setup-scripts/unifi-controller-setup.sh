#!/bin/sh

# Deploy an Unifi Controller / source: https://dchan.tech/raspberrypi/how-to-install-unifi-controller/

echo 'deb http://www.ui.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.list

sudo wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ubnt.com/unifi/unifi-repo.gpg

sudo apt-get install openjdk-8-jre-headless -y

sudo apt install ca-certificates apt-transport-https -y

sudo apt-get update
sudo apt-get install unifi -y

sudo systemctl enable unifi.service


