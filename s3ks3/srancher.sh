#!/bin/sh
# thx @ https://github.com/dkeightley 
echo "Installing K3S"
curl  -sfL https://get.k3s.io  | INSTALL_K3S_VERSION="v1.19.5+k3s2" sh -

PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)

echo "Downlading cert-manager CRDs"
wget -q -P /var/lib/rancher/k3s/server/manifests/ https://github.com/jetstack/cert-manager/releases/download/v0.15.0/cert-manager.crds.yaml

cat > /var/lib/rancher/k3s/server/manifests/rancher.yaml << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: cattle-system
---
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager
  labels:
    certmanager.k8s.io/disable-validation: "true"
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: cert-manager
  namespace: kube-system
spec:
  targetNamespace: cert-manager
  repo: https://charts.jetstack.io
  chart: cert-manager
  version: v0.15.0
  helmVersion: v3
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: rancher
  namespace: kube-system
spec:
  targetNamespace: cattle-system
  repo: https://releases.rancher.com/server-charts/latest/
  chart: rancher
  set:
    hostname: $PUBLIC_IP.xip.io
    replicas: 1
  helmVersion: v3
EOF

echo "Rancher should be booted up in a few mins"
