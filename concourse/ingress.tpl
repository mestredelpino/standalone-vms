apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  creationTimestamp: null
  name: concourse-ingress
spec:
  rules:
  - host: ${concourse-fqdn}
    http:
      paths:
      - backend:
          service:
            name: concourse-web
            port:
              number: 80
        path: /
        pathType: Prefix
status:
  loadBalancer: {}