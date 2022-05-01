#!/bin/bash
set -x
helm install app-backend-release app-backend-helm --set deployment.repository=$1
helm install app-frontend-release app-frontend-helm --set deployment.repository=$2

#helm install grafana-release grafana-helm-chart