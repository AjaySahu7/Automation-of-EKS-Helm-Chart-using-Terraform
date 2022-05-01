# Terraform template for AWS EKS with EC2 profile

This terraform template can be used to setup the AWS infrastructure
for a dockerized application running on EKS with a EC2 profile.

Due to the fact that EKS with EC2 profiles is not yet supported in all regions
(https://docs.aws.amazon.com/eks/latest/userguide/EC2.html) this template uses
the `us-east-2 (Ohio)`region.

## Prerequisites
This template requires `aws-iam-authenticator` and `openssl` to be installed

## Known limitations
* Although the namespace `default` is set in the EC2 profile (meaning
pods will be executed on managed nodes), CoreDNS can currently only run
on a EC2 profile if the CoreDNS deployment is patched after the
cluster is created (see https://github.com/terraform-providers/terraform-provider-aws/issues/11327
or https://docs.aws.amazon.com/eks/latest/userguide/EC2-getting-started.html#EC2-gs-coredns
for instructions). Therefore this template also creates a node-group for the `kube-system`
namespace, which is also used for the Ingress controller.

* By default the `config` file for `kubectl` is created in `~/.kube` directory. If any
configuration already exists there, it will be overwritten! To preserve any pre-existing
configuration, change the `kubeconfig_path` variable.