apiVersion: external-secrets.io/v1alpha1
kind: ExternalSecret
metadata:
  name: es-test
  namespace: ${bank_namespace}
spec:
  dataFrom:
  - key: hybrid-api-dev-secret
  refreshInterval: 1m
  secretStoreRef:
    kind: SecretStore
    name: banking
  target:
    creationPolicy: Owner
    name: poc-secret
