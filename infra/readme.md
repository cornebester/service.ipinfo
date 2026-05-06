# readme

creates vpc (using aws module) and eks cluster (using individual resources) with 2 worker nodes in private subnet ( 1x nat gw )

## requirements / prerequisites

- terraform
- aws cli and profile/secrets updated
- kubectl
- eksctl https://docs.aws.amazon.com/eks/latest/eksctl/installation.html
- helm

## create infra

- update your aws profile, region and secrets below
- create terraform secrets.auto.tfvars or other var file

```config
default_spot_notification_email_address = ""
my_trusted_ips = []
```


```shell
export AWS_PROFILE=dev-sandbox1
echo $AWS_PROFILE
```


```shell
terraform plan && terraform apply
```

### Create an IAM OIDC provider for the cluster using terraform ( default -  alternative to eksctl or console  )

Created by tf infra/oidc.tf

### Create an IAM OIDC provider for the cluster ( using eks-ctl, conditional if not using terraform )

[Create an IAM OIDC provider for the cluster](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html)

The eksctl utils associate-iam-oidc-provider command is used to enable IAM Roles for Service Accounts (IRSA) on an Amazon EKS cluster by associating an OpenID Connect (OIDC) provider with the cluster. This allows Kubernetes service accounts to assume IAM roles, granting fine-grained AWS permissions to pods.

```shell
    eksctl.exe utils associate-iam-oidc-provider --region=eu-west-1 --cluster=eks-lab --approve
```

## add cluster to kube config / switch context

using aws cli

```shell
    aws eks update-kubeconfig --region eu-west-1 --name eks-lab
```

using kubectl

```shell
    kubectl config use-context  arn:aws:eks:eu-west-1:146632099925:cluster/eks-lab
```


## ebs csi driver k8s service account add

- ebs csi driver / addon added with tf
- aws role and policy created with tf

create k8s service account

```shell
kubectl create serviceaccount ebs-csi-controller-sa \
  --namespace kube-system 
```

annotate k8s service account ( update with your aws iam role arn/account/region )

```shell
  kubectl annotate serviceaccount ebs-csi-controller-sa \
  -n kube-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::<replace_me_account_id>:role/ebs-csi-controller-sa-role
```

cleanup/delete if needed

```shell
kubectl delete serviceaccount ebs-csi-controller-sa \
  --namespace kube-system 
```


## metricserver

install metricserver ( default single pod )

```shell
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

```shell
    kubectl -n kube-system get deployment metrics-server -o yaml
```


## AWS LB Controller

### create k8s svc account and iam role ( manually )

create k8s service account

```shell
kubectl create serviceaccount eks-alb-controller-role \
  --namespace kube-system 
```

annotate k8s service account ( update with your aws iam role arn/account/region )

```shell
kubectl annotate serviceaccount eks-alb-controller-role \
  -n kube-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::<replace_me_account_id>:role/eks-alb-controller-role
```

### create k8s svc account and iam role ( using eksctl, conditional if not partially done with tf)

- **interferes with terraform created roles/policy**
- attach existing policy for LB controller ( run cloudformation )
- update role arn/account/region etc

```shell
    eksctl.exe create iamserviceaccount `
    --cluster=eks-lab `
    --namespace=kube-system `
    --name=eks-alb-controller-role `
    --attach-policy-arn=arn:aws:iam::146632099925:policy/AWSLoadBalancerControllerIAMPolicy `
    --region eu-west-1 `
    --approve
```

(optional) to delete

```shell
    eksctl.exe  delete iamserviceaccount --cluster=eks-lab --name eks-alb-controller-role
```

### install aws lb controller using helm

- https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/
- https://github.com/kubernetes-sigs/aws-load-balancer-controller
- https://github.com/aws/eks-charts/blob/master/stable/aws-load-balancer-controller/values.yaml
- https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/examples/2048/2048_full.yaml
- https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/examples/echo_server/#setup-the-aws-load-balancer-controller
- https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html
- https://repost.aws/knowledge-center/eks-alb-ingress-controller-fargate
- https://docs.aws.amazon.com/eks/latest/userguide/auto-configure-alb.html#_step_4_create_ingress
- https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
- https://docs.aws.amazon.com/eks/latest/userguide/auto-configure-nlb.html

```shell
helm repo add eks https://aws.github.io/eks-charts
```

```shell
helm repo update eks
```


**update cluster and vpc name/id**

```powershell
    helm.exe install aws-load-balancer-controller eks/aws-load-balancer-controller `
    -n kube-system `
    --set clusterName=<replace_me> 
    --set serviceAccount.create=false `
    --set serviceAccount.name=eks-alb-controller-role `
    --set vpcId=<replace_me> `
    --version 1.13.0
```

example 

```shell
    helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=eks-lab \
    --set serviceAccount.create=false \
    --set serviceAccount.name=eks-alb-controller-role \
    --set vpcId=vpc-<replace_me> \
    --version 1.13.0
```

verify install

```shell
    kubectl get deployment -n kube-system aws-load-balancer-controller
```

(optional)
```shell
    helm uninstall -n kube-system aws-load-balancer-controller
```

## Cleanup, delete

### remove all k8s deployed resources

    kubectl delete all --all -n my-apps 

### remove/uninstall aws loadbalancer controller

    helm list -A
    helm list --all
    helm list --all-namespaces
    helm uninstall -n kube-system aws-load-balancer-controller

### delete cloudformation IRSA roles created by eksctl

```shell
    eksctl.exe  delete iamserviceaccount --cluster=eks-lab --name eks-alb-controller-role
```

### delete aws oidc provider

- get oidc id from cluster

```shell
cluster_name=eks-lab
oidc_id=$(aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
echo $oidc_id
```

get account / region

```shell
ACCOUNT_ID=$(aws sts get-caller-identity | python3 -c "import sys,json; print (json.load(sys.stdin)['Account'])")
echo $ACCOUNT_ID
REGION=$(aws configure get region)
echo $REGION
CLUSTER_NAME=eks-lab
OIDCURL=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query "cluster.identity.oidc.issuer" --output text  | python3 -c "import sys; print (sys.stdin.readline().replace('https://',''))")
echo $OIDCURL
```

```shell
aws iam list-open-id-connect-providers
```

```shell
aws iam delete-open-id-connect-provider --open-id-connect-provider-arn arn:aws:iam::$ACCOUNT_ID:oidc-provider/$OIDCURL
```


