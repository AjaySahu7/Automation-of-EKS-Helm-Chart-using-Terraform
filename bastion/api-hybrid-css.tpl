apiVersion: external-secrets.io/v1alpha1
kind: SecretStore
metadata:
  name: pw
  namespace: ${bank_namespace}
spec:
  provider:
    aws:
      auth:
        jwt:
          serviceAccountRef:
            name: ${bank-service-account}
      region: ${region}
      service: SecretsManager
  retrySettings:
    maxRetries: 5
    retryInterval: 10s