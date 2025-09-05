# readme

creates vpc and eks cluster with 2 worker nodes in private subnet ( 1x nat gw )

# requirements

aws cli and profile/secrets updated
kubectl
eksctl
helm

## add / switch context

    aws eks update-kubeconfig --region eu-west-1 --name eks-lab

    kubectl config use-context  arn:aws:eks:eu-west-1:<replace_me>:cluster/eks-lab


## Configure oidc and svcs account using eksctl


    .\eksctl.exe utils associate-iam-oidc-provider --region=eu-west-1 --cluster=eks-lab --approve
 

    .\eksctl.exe create iamserviceaccount `
    --cluster=eks-lab `
    --namespace=kube-system `
    --name=aws-load-balancer-controller `
    --attach-policy-arn=arn:aws:iam::<replace_me>:policy/AWSLoadBalancerControllerIAMPolicy `
    --region eu-west-1 `
    --approve


(optional) to delete

    .\eksctl.exe  delete iamserviceaccount --cluster=eks-lab --name aws-load-balancer-controller


## istall aws lb controller using helm

update cluster and vpc name/id

    helm.exe install aws-load-balancer-controller eks/aws-load-balancer-controller `
    -n kube-system `
    --set clusterName=eks-lab `
    --set serviceAccount.create=false `
    --set serviceAccount.name=aws-load-balancer-controller `
    --set vpcId=vpc-0e8744a48c4433132 `
    --version 1.13.0

(optional)
    
    helm uninstall -n kube-system aws-load-balancer-controller
