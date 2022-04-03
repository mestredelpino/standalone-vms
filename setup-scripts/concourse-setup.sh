#!/bin/bash
. /home/ubuntu/.env


# Generate a SSH keypair.
if ! [ -f /home/ubuntu/.ssh/id_rsa ]; then echo "true"
  ssh-keygen -t rsa -f /home/ubuntu/.ssh/id_rsa -q -P ''
fi

# Install Docker.
sudo apt update
sudo apt-get update && \
sudo apt-get -y install docker.io && \
sudo ln -sf /usr/bin/docker.io /usr/local/bin/docker && \
sudo usermod -aG docker ubuntu

# Install kubectl
curl -LO https://dl.k8s.io/release/v1.20.1/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm /home/ubuntu/kubectl

# Install helm
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

# Deploy concourse on k3s with helm
helm repo add concourse https://concourse-charts.storage.googleapis.com/
helm pull concourse/concourse --untar

# Add the concourse fqdn and enable ingress on port 80
export hostname=`cat /etc/hosts | tail -1 | awk '{print $2}'`
yq e -i '.concourse.web.bindPort= 80' concourse/values.yaml
yq e -i ".concourse.ingress.enabled = true" concourse/values.yaml && service_fqdn="$hostname.$service_domain" yq e -i ".concourse.ingress.hosts = [ env(service_fqdn) ]" concourse/values.yaml
service_externalUrl="http://"$hostname".$service_domain" yq e -i ".concourse.web.externalUrl = env(service_externalUrl)"  concourse/values.yaml



# Edit the admin user
service_root=$service_root yq e -i ".concourse.web.auth.mainTeam.localUser = env(service_root)"  concourse/values.yaml
concourse_credentials="$concourse_username:$concourse_password" yq e -i ".secrets.localUsers = env(concourse_password)"  concourse/values.yaml


helm install concourse concourse/concourse --values concourse/values.yaml

# Create an ingress object

cat <<EOF > /home/ubuntu/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  creationTimestamp: null
  name: concourse-ingress
spec:
  rules:
  - host:
    http:
      paths:
      - backend:
          service:
            name:
            port:
              number: 80
        path: /
        pathType: Prefix
status:
  loadBalancer: {}
EOF

export concourse_selector="concourse-web"
export concourse_deployment=$(kubectl get deployments --namespace default -l "app=$concourse_selector" -o jsonpath="{.items[0].metadata.name}")
concourse_service=$concourse_selector yq e -i ".spec.rules[0].http.paths[0].backend.service.name = env(concourse_service)"  /home/ubuntu/ingress.yaml
ingress_host=$hostname".$service_domain" yq e -i ".spec.rules[0].host = env(ingress_host)"  /home/ubuntu/ingress.yaml
kubectl apply -f /home/ubuntu/ingress.yaml


# Wait until concourse is available
kubectl patch svc $concourse_deployment -p '{"spec": {"ports": [{"port": 80,"targetPort": 80}],"type": "NodePort"}}'
while [ $(kubectl get pods -l app=$concourse_selector -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ] ; do echo "Waiting for Concourse CI to be ready" && sleep 10s; done
echo "Concourse is running"








