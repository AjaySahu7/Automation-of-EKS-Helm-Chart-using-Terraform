apiVersion: external-secrets.io/v1alpha1
kind: ExternalSecret
metadata:
  name: app-frontend-ex-secret
  namespace: ${app_namespace}
spec:
  dataFrom:
  - key: app-frontend-secrets
  refreshInterval: 1m
  secretStoreRef:
    kind: SecretStore
    name: pw
  target:
    creationPolicy: Owner
    name: frontend-secret