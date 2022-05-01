#!/bin/bash
set -x
accountid=$1
region=$2
cluster=$3
eksctl utils associate-iam-oidc-provider --region $region --cluster $cluster --approve
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.0/docs/install/iam_policy.json
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam-policy.json
eksctl create iamserviceaccount --cluster=$cluster --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::$accountid:policy/AWSLoadBalancerControllerIAMPolicy --override-existing-serviceaccounts --region $region --approve

helm repo add eks https://aws.github.io/eks-charts
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=$cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller
