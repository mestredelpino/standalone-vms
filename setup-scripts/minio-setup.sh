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

# Install helm
sudo apt update
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# Install k3s
curl -sfL https://get.k3s.io | sh -  
echo "Waiting for for k3s to be available, this can take up to a minute"
sleep 60s

mkdir .kube
sudo chown -R $USER $HOME/.kube
sudo chown -R $USER /etc/rancher/
cp /etc/rancher/k3s/k3s.yaml .kube/config

# Deploy minIO on k3s with helm
helm repo add bitnami https://charts.bitnami.com/bitnami && \
helm pull bitnami/minio --untar && \
service_root=$service_root yq e -i '.auth.rootUser= env(service_root)' minio/values.yaml && \
service_root_password=$service_root_password yq e -i '.auth.rootPassword= env(service_root_password)' minio/values.yaml && \
yq e -i '.ingress.enabled= true' minio/values.yaml && \
export hostname=`cat /etc/hosts | tail -1 | awk '{print $2}'`
service_fqdn=$hostname".$service_domain" yq e -i '.ingress.hostname= env(service_fqdn)' minio/values.yaml && \
helm install minio bitnami/minio --values minio/values.yaml

while [ $(kubectl get pods -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ] ; do echo "Waiting for MinIO to be ready" && sleep 10s; done




