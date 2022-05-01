#!/bin/bash
set -x
helm install hybridfi-docs-release docs-hybrid --set repository=$1 --set ingress.host=$2
helm install hybridfi-api-release hybrid-api --set repository=$1   --set ingress.host=$3