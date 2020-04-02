# Learn Kubernetes

Krystof learns Kubernetes.

The following assumes you have Docker installed and working
(and are logged in to Docker Hub), and that you have a
[Microk8s](https://microk8s.io/#get-started) cluster working.

**Goals:**
1. Build a simple Hello World python container image
2. Push the image to a repository
3. deploy it to a local Microk8s cluster
    - 3.1 - have k8s provide a secret to the container (TODO)
4. have kubernetes periodically run the hello world script (TODO)
5. Same 1-4 above, but now with a private image (TODO)

**Questions:**
- should the pod with the image run continually while k8s schedules jobs on it,
  or should it be spun up as needed by k8s' cron?
- does the container need a storage volume?
-


# 1. Build a Container Image

The repo contains a very simple python "Hello World" application.

To create a container from it, run

    docker build -t hello-py:v1 .


# 2. Push the image to a repository

In this case to docker hub @ `krystofl/hello-py`
(adapted from https://stackoverflow.com/a/58633144)

    docker tag hello-py:v1 localhost:5000/hello-py:v1
    docker push krystofl/hello-py:v1



# 3. Get the container running on Microk8s

To watch what's going on, you could use
`watch microk8s kubectl get pods` and
`watch microk8s kubectl get deployments`

Start microk8s: `microk8s start`

Create a deployment:

    microk8s kubectl create -f deployment.yaml

A [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
provides declarative updates for Pods and ReplicaSets.


## 3.1 Have Kubernetes pass a secret to the image

TODO


# 4. Get Kubernetes to periodically run the script

[Docs](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/)

The cronjob is specified in `cronjob.yaml`.
It runs `hello.py` once per minute.

To schedule it, run

    microk8s kubectl create -f cronjob.yaml

To view that it's scheduled, run

    microk8s kubectl get cronjob hello-py-cronjob

As always, you can see the pods created with `watch microk8s kubectl get pods`

To view the output (logs), run

    microk8s kubectl logs <<PODNAME>>

where <<PODNAME>> is the name of a pod.

To delete the cronjob, run `microk8s kubectl delete cronjob hello-py-cronjob`



# 5. Do it all with a private container image

TODO










# Notes

## Working with local-only images (TODO/WIP)
I haven't been able to get this to work yet, so this is WIP:
(adapted from https://stackoverflow.com/a/59699968)

This also looks like a good guide for a local deployment:
https://blog.payara.fish/what-is-kubernetes

And straight from Docker: https://www.docker.com/blog/how-to-use-your-own-registry/

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


## Resources

This was originally forked from https://github.com/rackbrainz/kubernetes-101,
which accompanies
[this series of Medium posts](https://medium.com/rackbrains/kubernetes-101-part-1-8bd033f3ff33).
