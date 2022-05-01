apiVersion: external-secrets.io/v1alpha1
kind: ExternalSecret
metadata:
  name: docs-admin-ex-secret
  namespace: ${bank_namespace}
spec:
  dataFrom:
  - key: docs-admin-user
  refreshInterval: 1m
  secretStoreRef:
    kind: SecretStore
    name: banking
  target:
    creationPolicy: Owner
    name: docs-admin-secret
---
apiVersion: external-secrets.io/v1alpha1
kind: ExternalSecret
metadata:
  name: docs-main-ex-secret
  namespace: ${bank_namespace}
spec:
  dataFrom:
  - key: docs-main-user
  refreshInterval: 1m
  secretStoreRef:
    kind: SecretStore
    name: banking
  target:
    creationPolicy: Owner
    name: docs-main-secret
