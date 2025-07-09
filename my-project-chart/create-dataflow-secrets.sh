#!/bin/bash

# This script creates Kubernetes generic secrets for the k8s-dataflow-project Helm chart.
# IMPORTANT:
# 1. Replace all placeholder values (e.g., "<YOUR_FERNET_KEY>") with your actual, strong secret values.
# 2. Replace "<YOUR_NAMESPACE>" with the Kubernetes namespace where you will deploy your Helm chart.
# 3. Ensure you have kubectl configured and authenticated to your Kubernetes cluster.

# Define your namespace here
NAMESPACE="default" # <--- IMPORTANT: Change this to your desired Kubernetes namespace

echo "Creating secrets in namespace: $NAMESPACE"

# Airflow Fernet Key and Webserver Secret Key
# Generate a Fernet key: python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
# Generate a Webserver Secret Key: python -c "import os; print(os.urandom(16).hex())"
kubectl create secret generic airflow-secrets \
  --from-literal=fernet-key='<YOUR_FERNET_KEY>' \
  --from-literal=webserver-secret-key='<YOUR_WEBSERVER_SECRET_KEY>' \
  -n "$NAMESPACE" || echo "airflow-secrets might already exist or there was an error."

# Airflow PostgreSQL Database Password
kubectl create secret generic airflow-postgresql-secret \
  --from-literal=postgresql-password='<YOUR_AIRFLOW_POSTGRES_PASSWORD>' \
  -n "$NAMESPACE" || echo "airflow-postgresql-secret might already exist or there was an error."

# Jenkins Admin Password
kubectl create secret generic jenkins-admin-secret \
  --from-literal=admin-password='<YOUR_JENKINS_ADMIN_PASSWORD>' \
  -n "$NAMESPACE" || echo "jenkins-admin-secret might already exist or there was an error."

# Grafana Admin Password
kubectl create secret generic grafana-admin-secret \
  --from-literal=admin-password='<YOUR_GRAFANA_ADMIN_PASSWORD>' \
  -n "$NAMESPACE" || echo "grafana-admin-secret might already exist or there was an error."

# MinIO Credentials (Root User and Password)
kubectl create secret generic minio-credentials \
  --from-literal=root-user='<YOUR_MINIO_ROOT_USER>' \
  --from-literal=root-password='<YOUR_MINIO_ROOT_PASSWORD>' \
  -n "$NAMESPACE" || echo "minio-credentials might already exist or there was an error."

# Hive Metastore Database Password (for both hiveMetastore and hivePostgresql)
kubectl create secret generic hive-metastore-db-secret \
  --from-literal=db-password='<YOUR_HIVE_METASTORE_DB_PASSWORD>' \
  -n "$NAMESPACE" || echo "hive-metastore-db-secret might already exist or there was an error."

# Hive Metastore S3 Credentials (Access Key and Secret Key)
kubectl create secret generic hive-metastore-s3-secret \
  --from-literal=access-key='<YOUR_HIVE_S3_ACCESS_KEY>' \
  --from-literal=secret-key='<YOUR_HIVE_S3_SECRET_KEY>' \
  -n "$NAMESPACE" || echo "hive-metastore-s3-secret might already exist or there was an error."

# NOTE ON INFLUXDB TOKEN:
# The 'influxdb-auth' secret for InfluxDB's token is typically managed and created
# automatically by the InfluxDB Helm chart itself when it's deployed.
# You usually do NOT need to create this secret manually. Grafana will
# automatically pick it up once InfluxDB is deployed.
# If you need to manually set the InfluxDB admin token, you would configure it
# directly in the InfluxDB chart's values.yaml (e.g., influxdb.auth.token: <YOUR_TOKEN>)
# or use its specific methods for existing secrets.

echo "All specified secrets creation commands executed. Please check output for any errors."
echo "Remember to update the placeholders in this script with your actual values before running."
