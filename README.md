# Learn Kubernetes

Krystof learns Kubernetes.

The following assumes you have Docker installed and working
(and are logged in to Docker Hub), and that you have a
[Microk8s](https://microk8s.io/#get-started) cluster working.


## Create and Publish a Container Image

The repo contains a very simple python "Hello World" application.

To create a container from it, run

    docker build -t hello-py:v1 .


### Option 1: make the container available on a local registry
(adapted from https://stackoverflow.com/a/59699968)

1. Start a local registry server:
```
docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

2. Tag your image:
```
sudo docker tag hello-py:v1 localhost:5000/hello-py
```

3. Push it to a local registry:
```
sudo docker push localhost:5000/hello-py
```



### Option 2: push the image to Docker Hub
(adapted from https://stackoverflow.com/a/58633144)

To push the container to the Docker registry, so that Kubernetes can find it there later
(adapted from https://stackoverflow.com/a/59699968):

    docker tag hello-py:v1 krystofl/hello-py:v1
    docker push krystofl/hello-py:v1



## Get the container running on Microk8s

Start microk8s: `microk8s start`

Create a deployment:

    microk8s kubectl create -f deployment.yaml

A [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
provides declarative updates for Pods and ReplicaSets.

**NOTE: this is probably not needed for hello-py?**
Set up port forwarding to talk to the Pod:

    POD_NAME=$(microk8s kubectl get pods | grep kubernetes-101 | awk '{print $1}')
    microk8s kubectl port-forward $POD_NAME 3000:3000



# Note on Working with local-only images
Per [this](https://stackoverflow.com/a/59699968) Stack Overflow answer,
if working with only local images, need to start a local docker TODO


# Monitoring
To keep an eye on what's going on, you could use
`watch microk8s kubectl get pods` and
`watch microk8s kubectl get deployments`


# Notes

This was originally forked from https://github.com/rackbrainz/kubernetes-101,
which accompanies
[this series of Medium posts](https://medium.com/rackbrains/kubernetes-101-part-1-8bd033f3ff33).
