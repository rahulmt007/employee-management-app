# Kubernetes Guide

## Overview

This project includes Kubernetes manifests so the Employee Management Application can be demonstrated on a local Kubernetes cluster or adapted for a production cluster.

The Kubernetes setup includes:

- Namespace
- ConfigMap for non-secret application config
- Secret example for database credentials
- Web app Deployment with two replicas
- ClusterIP Service
- Optional Ingress
- Optional HorizontalPodAutoscaler
- Optional local MySQL manifest for development demos

## Cost Note

Do not create EKS just for this portfolio release if you are trying to stay inside AWS Free Tier. EKS has control plane costs.

Recommended demo options:

- Docker Desktop Kubernetes
- `kind`
- `minikube`

Use AWS EKS later only if you intentionally want a production Kubernetes deployment.

## Files

| File | Purpose |
| --- | --- |
| `k8s/namespace.yaml` | Creates the `employee-management` namespace |
| `k8s/configmap.yaml` | Stores `DB_HOST` and `DB_NAME` |
| `k8s/secret.example.yaml` | Example secret values for local development |
| `k8s/deployment.yaml` | Runs the PHP app pods |
| `k8s/service.yaml` | Exposes the app inside the cluster |
| `k8s/ingress.yaml` | Optional HTTP ingress route |
| `k8s/hpa.yaml` | Optional CPU-based autoscaling |
| `k8s/mysql-dev.yaml` | Optional local MySQL database for demos |

## Build Local Image

For Docker Desktop Kubernetes:

```bash
docker build -t employee-management-app:local .
```

For `kind`:

```bash
docker build -t employee-management-app:local .
kind load docker-image employee-management-app:local
```

For `minikube`:

```bash
minikube image build -t employee-management-app:local .
```

## Local Kubernetes Demo With MySQL

Apply the manifests:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.example.yaml
kubectl apply -f k8s/mysql-dev.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Wait for pods:

```bash
kubectl get pods -n employee-management
```

Port forward the application:

```bash
kubectl port-forward -n employee-management service/employee-management-service 8080:80
```

Open:

```text
http://localhost:8080
```

Health check:

```text
http://localhost:8080/healthcheck.php
```

## Optional Ingress

Install or enable an ingress controller first, such as NGINX Ingress.

Then apply:

```bash
kubectl apply -f k8s/ingress.yaml
```

For local testing, add a hosts file entry if needed:

```text
127.0.0.1 employee-management.local
```

Then open:

```text
http://employee-management.local
```

## Optional Autoscaling

The HPA requires metrics-server.

Apply:

```bash
kubectl apply -f k8s/hpa.yaml
```

Check:

```bash
kubectl get hpa -n employee-management
```

## Production-Style RDS Configuration

For production or EKS, prefer Amazon RDS instead of the local `mysql-dev.yaml`.

Change `k8s/configmap.yaml`:

```yaml
data:
  DB_HOST: your-rds-endpoint.us-east-1.rds.amazonaws.com
  DB_NAME: employeedb
```

Create a real Kubernetes Secret instead of committing credentials:

```bash
kubectl create secret generic employee-db-secret \
  -n employee-management \
  --from-literal=DB_USER='<db-user>' \
  --from-literal=DB_PASS='<db-password>' \
  --from-literal=MYSQL_ROOT_PASSWORD='unused-for-rds'
```

Do not apply `k8s/mysql-dev.yaml` when using RDS.

## Verification Checklist

- App Deployment has desired replicas available
- Service exists and points to app pods
- Health check endpoint returns `OK`
- Add Employee works
- Search Employee works
- Edit Employee pre-fills values
- Update Employee saves changes
- Delete Employee works

## Cleanup

For local clusters:

```bash
kubectl delete namespace employee-management
```

This removes all resources created in the namespace, including the local MySQL PVC if the storage class allows cleanup.

## Release Notes

These manifests are intended to make the project Kubernetes-ready without requiring an active paid AWS EKS cluster.
