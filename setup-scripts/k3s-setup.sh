#!/bin/bash
. /home/ubuntu/.env

# Generate a SSH keypair.
if ! [ -f /home/ubuntu/.ssh/id_rsa ]; then echo "true"
  ssh-keygen -t rsa -f /home/ubuntu/.ssh/id_rsa -q -P ''
fi

# Install Docker.
sudo apt-get update
sudo apt-get -y install docker.io
sudo ln -sf /usr/bin/docker.io /usr/local/bin/docker
sudo usermod -aG docker ubuntu

# Install kubectl
curl -LO https://dl.k8s.io/release/v1.20.1/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm /home/ubuntu/kubectl

# Install k3s
curl -sfL https://get.k3s.io | sh -
echo "Waiting for for k3s to be available, this can take up to a minute"
sleep 60s

mkdir .kube
sudo chown -R $USER $HOME/.kube
sudo chown -R $USER /etc/rancher/
cp /etc/rancher/k3s/k3s.yaml .kube/config