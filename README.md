# service.ipinfo

_Microservice that lookup host/cluster egress ip by using ipinfo.io sdk and return with some local information as html_

Flask application and optionally fronted with gunicorn wsgi. 4 workers with /dev/shm workdir. get log level from env.

# Application

* Python 3.10+
* Flask 
* Gunicorn
* ipinfo
* redis

* autopep8

## ports

flask / app: 81
gunicorn: 8081
docker/container mapped: 8081:8081
k8s service loadbalancer: 81

81(lb) --> 8081(service) --> 8081(deployment/pods/container/gunicorn) --> 81(flask/app)

# Get started

    ./venv_create.sh
    source ./venv/bin/activate
    pip3 install -r ./src/requirements.txt

# Dependencies

* ipinfo.io
* * https://github.com/ipinfo/python
* * https://ipinfo.io/account


## env vars

### Bash / wsl 1.0

    export IPINFO_ACCESS_TOKEN=xxxxxxxxxxxxxx
    export IPINFO_ACCESS_TOKEN=<see lastpass>
    export GUNICORN_WORKERS=4
    export LOG_LEVEL=WARNING # OR (log levels = DEBUG,INFO,ERROR)
    export REDIS_HOST=localhost
    export LOG_LEVEL=DEBUG

OR
    .env file from 1pass

check

    env
    printenv
    
#### Powershell/win

    $Env:IPINFO_ACCESS_TOKEN = "0b6199f5f6f759"
    $Env:LOG_LEVEL = "DEBUG"
    Get-ChildItem Env:

py _path/filename_

### run flask app

    cd /src
    python application.py

    curl http://localhost:81

### run flask app fronted with gunicorn ( LINUX OR NIX CONTAINER ONLY)

    cd /src
    gunicorn -b 0.0.0.0:${WSGI_PORT:-8081} --access-logfile=- --error-logfile=- --log-level=${LOG_LEVEL} --timeout=600 --workers=4 application
    
    curl http://localhost:8081

## tests / troubleshooting

### httpie
    http localhost:81/healthr && http localhost:81/healthl && http localhost:81 && http localhost:81/test

### root path
    curl -vv http://localhost:81

### readines path
    curl -vv http://localhost:81/healthr

    kill redis container and will return 500 statuscode

### liveness path
    curl -vv http://localhost:81/healthl


#### build ipinfo image for ECR ( AWS )

x86/amd64

    docker buildx build --platform linux/amd64 -t service.ipinfo:latest --load .  *> build-win-amd64.log

arm64

    docker buildx build --platform linux/arm64 -t service.ipinfo-arm64:latest --load .  *> build-win-arm64.log

    aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 146632099925.dkr.ecr.eu-west-1.amazonaws.com


publish to registry

login

    export AWS_PROFILE="default"
    $Env:AWS_PROFILE="default"
    aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 146632099925.dkr.ecr.eu-west-1.amazonaws.com

optional

    aws ecr create-repository --repository-name service.ipinfo --region eu-west-1 --image-scanning-configuration scanOnPush=true --image-tag-mutability MUTABLE

tag and push

    docker tag service.ipinfo:latest 146632099925.dkr.ecr.eu-west-1.amazonaws.com/service.ipinfo:latest
    docker push 146632099925.dkr.ecr.eu-west-1.amazonaws.com/service.ipinfo:latest


## k8s 

see ./k8s_config/readme.md for details plus

* update ./k8s_config/service-ipinfo-deployment.yaml image, configmap and secret
* and add/modify taints and tolerations depending on cloud vendor