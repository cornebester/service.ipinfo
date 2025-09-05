# readme

_Deploy and manage my ipinfo microservice_

## Dependencies

* redis
* ipinfo api key secret ( ipinfo account - duh) - set as k8s secret and passed as env var
* log level set config map and passed as env var

# deploy manifests

## dependecies

* image in acr with access
* secret and config map  

* authenticate control pane - copy string from portal
* auth for rbac 

deploy 

    kubectl create ns my-apps

    kubectl apply -f ./k8s_config/redis-deployment.yaml --namespace my-apps
    kubectl apply -f ./k8s_config/redis-service.yaml --namespace my-apps
    kubectl apply -f ./k8s_config/service-ipinfo-deployment.yaml --namespace my-apps
    kubectl apply -f ./k8s_config/service-ipinfo-service.yaml --namespace my-apps

    kubectl delete -f ./k8s_config/redis-service.yaml --namespace my-apps
    kubectl delete -f ./k8s_config/redis-deployment.yaml --namespace my-apps
    kubectl delete -f ./k8s_config/service-ipinfo-service.yaml --namespace my-apps
    kubectl delete -f ./k8s_config/service-ipinfo-deployment.yaml --namespace my-apps

To update deployment, just edit manifest and apply again

    kubectl rollout status deployment.apps/application -n my-apps 

## envs / secret

    kubectl get secrets,configmap -A -o wide
    kubectl get secrets,configmap -n <namespace>

secrets

    kubectl create secret generic ipinfo-access-token --from-literal=ipinfo_key=xxxx -n my-apps
    kubectl get secret ipinfo-access-token -n my-apps
    kubectl get secret ipinfo-access-token -o yaml -n my-apps
    kubectl get secret ipinfo-access-token -o jsonpath='{.data}' -n my-apps | jq .ipinfo_key

    echo "xxxxx" | base64 --decode  

    kubectl exec -it application-c8bf97c4f-kvwnq printenv

UPDATE secret

    kubectl create secret generic ipinfo-access-token --from-literal=ipinfo_key=xxxx -n my-apps --dry-run -o yaml `
    | kubectl apply -f -

configmap

    kubectl create configmap service-ipinfo --from-env-file=./k8s_config/myconfigs.txt -n my-apps
    kubectl describe configmaps service-ipinfo  -n my-apps
    kubectl get configmaps service-ipinfo -o yaml -n my-apps
    kubectl exec -it application-7499f9c4f-2nqmj printenv -n my-apps

    kubectl delete configmap service-ipinfo

UPDATE configmap

    kubectl create configmap service-ipinfo --from-env-file=./k8s_config/myconfigs.txt -n my-apps --dry-run -o yaml \
    | kubectl apply -f -

Alternate ( having secrets in config map not ideal)

    kubectl create configmap <> --from-env-file=.env
