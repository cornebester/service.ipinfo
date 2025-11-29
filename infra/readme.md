# readme

creates vpc (using aws module) and eks cluster (using individual resources) with 2 worker nodes in private subnet ( 1x nat gw )

# requirements

terraform 
aws cli and profile/secrets updated
kubectl
eksctl https://docs.aws.amazon.com/eks/latest/eksctl/installation.html
helm

## add / switch context

    aws eks update-kubeconfig --region eu-west-1 --name eks-lab

    kubectl config use-context  arn:aws:eks:eu-west-1:146632099925:cluster/eks-lab


## Configure oidc and svcs account using eksctl

[Create an IAM OIDC provider for the cluster](https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html)

```
The eksctl utils associate-iam-oidc-provider command is used to enable IAM Roles for Service Accounts (IRSA) on an Amazon EKS cluster by associating an OpenID Connect (OIDC) provider with the cluster. This allows Kubernetes service accounts to assume IAM roles, granting fine-grained AWS permissions to pods.
```

    eksctl.exe utils associate-iam-oidc-provider --region=eu-west-1 --cluster=eks-lab --approve
 

 ## create k8s svc account and iam role / attach existing policy for LB controller ( run cloudformation )

    eksctl.exe create iamserviceaccount `
    --cluster=eks-lab `
    --namespace=kube-system `
    --name=aws-load-balancer-controller `
    --attach-policy-arn=arn:aws:iam::146632099925:policy/AWSLoadBalancerControllerIAMPolicy `
    --region eu-west-1 `
    --approve


(optional) to delete

    eksctl.exe  delete iamserviceaccount --cluster=eks-lab --name aws-load-balancer-controller


## install aws lb controller using helm

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

    helm.exe install aws-load-balancer-controller eks/aws-load-balancer-controller `
    -n kube-system `
    --set clusterName=eks-lab `
    --set serviceAccount.create=false `
    --set serviceAccount.name=aws-load-balancer-controller `
    --set vpcId=<replace_me> `
    --version 1.13.0

verify install

    kubectl get deployment -n kube-system aws-load-balancer-controller

(optional)
    
    helm uninstall -n kube-system aws-load-balancer-controller


## Cleanup, delete

remove all k8s deployed resources

    kubectl delete all --all -n my-apps 

remove/uninstall aws loadbalancer controller

    helm list -A
    helm list --all
    helm list --all-namespaces
    helm uninstall -n kube-system aws-load-balancer-controller

delete cloudformation IRSA roles created by eksctl

    eksctl.exe  delete iamserviceaccount --cluster=eks-lab --name aws-load-balancer-controller

delete aws oidc provider 

    aws iam list-open-id-connect-providers

ACCOUNT_ID=$(aws sts get-caller-identity | python3 -c "import sys,json; print (json.load(sys.stdin)['Account'])")
echo $ACCOUNT_ID
                
OIDCURL=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query "cluster.identity.oidc.issuer" --output text  | python3 -c "import sys; print (sys.stdin.readline().replace('https://',''))")
echo $OIDCURL
aws iam delete-open-id-connect-provider --open-id-connect-provider-arn arn:aws:iam::$ACCOUNT_ID:oidc-provider/$OIDCURL
aws iam list-open-id-connect-providers
