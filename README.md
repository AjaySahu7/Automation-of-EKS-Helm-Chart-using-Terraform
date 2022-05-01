For Secrets Management 

We use AWS Secret Manager to store secrets of application and AWS resources.  

How Pod in EKS Cluster access secrets from AWS Secret Manager? 

Kubernetes-external-secrets allows you to use external secret management systems, like AWS Secrets Manager, to securely add Secrets in Kubernetes, so Pods can access Secrets normally. 

CI/CD Pipeline Process 

As soon as a developer creates/merges a Pull Request in the Gitlab repository to review proposed changes to the code. When the pull request is merged into the respective branch in the Gitlab repository, Gitlab CI upload the updated code to S3 bucket. AWS CodeBuild automatically detects the changes to the S3 bucket and starts code build job which was deployed as a pod in the EKS cluster & building the image based on the buildspec.yml file which is available in each application repository. 

As soon as the build is completed the image will be tagged as build tag and it will be pushed to the respective application ECR (Elastic Container Registry). 

Once the image is pushed to ECR, Codebuild trigger the helm command to upgrade the helm charts of the respective application.  

Infrastructure  

Use Terraform to configure the infrastructure as code 

Set up a monitoring system for logs, traffic and server utilization 

We use Prometheus and Grafana for monitoring tool and EFK (Elastic search, Fluentd and Kibana) deployed through helm charts. 

Authenticate Grafana using google authentication. 

Set up appropriate role-based access policies and groups 

Kubernetes cluster API access control 

Hashi Corp Terraform is an infrastructure as code tool that lets you define both cloud and on-prem resources in human-readable configuration files that you can version reuse, and share. You can then use a consistent workflow to provision and manage all of your infrastructures throughout their lifecycle. Terraform can manage low-level components like compute, storage, and networking resources, as well as high-level components like DNS entries and SaaS features. 

Terraform provides modules that allow us to abstract away re-usable parts, which we can configure once, and use everywhere. Modules allow us to group resources together, define input variables that are used to change needed resource configuration parameters, and define output variables that other resources or modules can use. Modules are basically like files with exposed input and output variables that facilitate reuse. We don’t need to do anything special to create a module, it is just like our terraform configuration which runs independently. Modules can’t inherit or reference parent resources, we need to pass them to the module explicitly as input variables. Modules are self-contained packages that can be shared across teams for different projects. 

Using modules in terraform is similar to using resources except we use module clause for modules instead of resource clause. 

We use the following modules: 

VPC 

EKS 

S3 

Bastion Host 

RDS 

Helm 

Route53 

 

 

 

 

In VPC modules the following resources are provisioned. 

VPC, 2 public and private subnets, Internet Gateway, NAT Gateway and Cloud-Watch Log Groups 

In EKS modules, EKS Cluster, IAM OpenID Connect Provider, EKS Node Group, Attached IAM Roles with Cluster and Node Group 

In S3 Modules, S3 buckets and encrypt the S3 bucket with KMS keys 

In Bastion Hosts Modules, Ec2 machine, security group, and using file provisioner to transfer External secrets and Secret Store. We will talk about External secrets and Secret Store later. 

RDS and security group have been provisioned in RDS Module. 

For Monitoring and Logging tools, Prometheus, Grafana, Elasticsearch, Kibana, External Secret, and External-dns Helm chart are deployed in Helm Module. 

ECR Repository and ECR Lifecycle policy in ECR Module. 

Route 53 record and Route 53 Zone in route53 Module. 

Application is deployed through Helm-charts. 

 Security Best Practice 

 Application and Infrastructure Sensitive Secrets are stored in Secret Manager. While Terraform provisions Infrastructure, its fetches secrets from Secret Manager. 

Application Environment variables which are running In EKS Cluster, fetch from Secret Manager by Secret Store and External-Secrets. 

EKS Cluster is secured by VPN like Twingate.  

 

CI-CD Process 

Code pipeline is used for deployment process and provisioned through Terraform. 

 

 

 