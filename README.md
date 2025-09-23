# Trendify Static Web App Deployment on EKS with CI/CD

This repository contains a static web application (`Trendify`) deployed on AWS EKS using Terraform for infrastructure, Jenkins for CI/CD, Docker for containerization, and Prometheus/Grafana for monitoring.

## Overview
- **Application**: Static HTML/CSS/JS app served by Nginx, built from the `dist` folder.
- **Infrastructure**: VPC, EC2 for Jenkins, EKS cluster (`trend-eks`).
- **CI/CD**: Jenkins pipeline builds Docker image, pushes to DockerHub (`dineshpowercloud/trend-app:latest`), deploys to EKS.
- **Deployment URL**: `http://k8s-default-trendser-4cf51ce1f2-0e2420a4955cd2e8.elb.us-east-1.amazonaws.com:3000` (serves `dist/index.html`).
- **Monitoring**: Prometheus and Grafana in `monitoring` namespace (Grafana at `http://adde79f1c21a049cab4a13296b541dfd-176828098.us-east-1.elb.amazonaws.com`, admin/prom-operator).

## Prerequisites
- AWS Account with admin access.
- GitHub account and DockerHub account (`dineshpowercloud`).
- Tools: AWS CLI v2, kubectl, Terraform, Helm, eksctl.

## Setup Instructions

### 1. Infrastructure with Terraform
- Clone Terraform repo: `git clone https://github.com/dineshpowercloud/terraform-infra.git && cd terraform-infra`.
- Run:
- terraform init
- terraform apply --auto-approve

- - Outputs:
- Jenkins URL: `http://<ec2-public-ip>:8080`.
- EKS Cluster: `trend-eks`.
- Subnets: Tagged with `kubernetes.io/cluster/trend-eks=shared` and `kubernetes.io/role/elb=1`.

### 2. Jenkins Setup
- Unlock Jenkins with initial password: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`.
- Install plugins: Docker Pipeline, Git, Kubernetes, Pipeline, AWS Credentials.
- Add credentials:
- GitHub PAT: ID `github-login`.
- DockerHub: ID `dockerhub-creds` (username: `dineshpowercloud`, password).
- Configure GitHub webhook in repo settings (Payload URL: `http://<ec2-public-ip>:8080/github-webhook/`).

### 3. Pipeline Explanation
The `Jenkinsfile` defines a declarative pipeline:
- **Checkout**: Pulls code from `main` branch.
- **Build Docker**: Builds `dineshpowercloud/trend-app:${BUILD_NUMBER}` using `Dockerfile` (copies `dist/` to `/usr/share/nginx/html/`).
- **Push to DockerHub**: Logs in and pushes `latest` tag.
- **Deploy to EKS**: Updates kubeconfig, applies `k8s/deployment.yaml` and `k8s/service.yaml`, restarts deployment.
- **Post**: Logs out of DockerHub.

### 4. Kubernetes Manifests
- `k8s/deployment.yaml`: Deploys 2 replicas of `trend-app` using `dineshpowercloud/trend-app:latest`.
- `k8s/service.yaml`: LoadBalancer on port `3000` to `80`.
- `k8s/trend-service-monitor.yaml`: ServiceMonitor for Prometheus.

### 5. Monitoring
- Helm: `helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace`.
- Grafana: `http://adde79f1c21a049cab4a13296b541dfd-176828098.us-east-1.elb.amazonaws.com` (admin/prom-operator).
- Data Source: Prometheus at `http://prometheus-operated:9090`.
- Dashboard: Query `rate(http_requests_total[5m])` for app metrics.

### 6. Screenshots
- **Jenkins Pipeline**: ![Jenkins Pipeline](screenshots/jenkins-pipeline.png)
- **EKS Deployment**: ![EKS Pods](screenshots/eks-pods.png)
- **App Access**: ![Trendify App](screenshots/app-access.png)
- **Grafana Dashboard**: ![Grafana Dashboard](screenshots/grafana-dashboard.png)

### 7. Cleanup
- `terraform destroy --auto-approve` to remove infrastructure.

### 8. Troubleshooting
- Docker permission: Add `jenkins` to `docker` group (`sudo usermod -a -G docker jenkins`).
- EKS Authentication: Map IAM user/role in `aws-auth` ConfigMap.
- LoadBalancer Pending: Add subnet tags (`kubernetes.io/role/elb=1`).

## LoadBalancer ARN
- LoadBalancer ARN: `arn:aws:elasticloadbalancing:us-east-1:342137541267:loadbalancer/app/k8s-default-trendser-4cf51ce1f2/4cf51ce1f2-0e2420a4955cd2e8` (retrieve via AWS Console > ELB > Load Balancers).

## Repository Structure
Trend/
├── Dockerfile
├── Jenkinsfile
├── dist/
│   ├── index.html
│   ├── vite.svg
│   └── assets/
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── trend-service-monitor.yaml
└── .gitignore
└── .dockerignore

