apiVersion: external-secrets.io/v1alpha1
kind: ExternalSecret
metadata:
  name: app-backend-ex-secret
  namespace: ${app_namespace}
spec:
  dataFrom:
  - key: pw-dev-secrets
  refreshInterval: 1m
  secretStoreRef:
    kind: SecretStore
    name: pw
  target:
    creationPolicy: Owner
    name: app-backend-secret