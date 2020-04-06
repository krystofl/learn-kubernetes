# Learn Kubernetes

Krystof learns Kubernetes.

The following assumes you have Docker installed and working
(and are logged in to Docker Hub), and that you have a
[Microk8s](https://microk8s.io/#get-started) cluster working.

**Goals:**
1. Build a simple Hello World python container image
2. Push the image to a repository
3. Deploy it as a CronJob to a local Microk8s cluster
   - 3.1. Provide a secret to the container
   - 3.2. Mount a volume (TODO)
5. Same 1-4 above, but now with a private image (TODO)

**Questions & TODOs:**
- remaining TODOs from above
- hello-py is a great example of a cronjob. Add back in the node.js example
for deployments
- add namespaces
- add contexts (namespace + cluster)?
- add a Makefile that runs all these different jobs?



## Keep an eye on things
To watch what's going on, you could use
`watch microk8s kubectl get pods` and
`watch microk8s kubectl get deployments`



# 1. Build a Container Image

The repo contains a very simple python "Hello World" application.

To create a container from it, run

    docker build -t hello-py:latest .


# 2. Push the image to a repository

In this case to docker hub @ `krystofl/hello-py`
(adapted from https://stackoverflow.com/a/58633144)

    docker tag hello-py:latest krystofl/hello-py:latest
    docker push krystofl/hello-py:latest



# 3. Deploy it as a CronJob to a local Microk8s cluster

[CronJob Docs](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/)

Start microk8s: `microk8s start`

The cronjob is specified in `cronjob.yaml`.
It runs `hello.py` once per minute.

To schedule it, run

    microk8s kubectl create -f cronjob.yaml

To view that it's scheduled, run

    microk8s kubectl get cronjob hello-py-cronjob

To view the output (logs), run

    microk8s kubectl logs <<PODNAME>>

where <<PODNAME>> is the name of a pod.

To delete the cronjob, run

    microk8s kubectl delete cronjob hello-py-cronjob



## 3.1 Have Kubernetes pass a secret to the image

[Secrets docs](https://kubernetes.io/docs/concepts/configuration/secret/)

There's a secret in `secret.txt`.

To create the secret in Microk8s, run

    microk8s kubectl create secret generic my-secret --from-file=./secret.txt

The filename (`secret.txt`) in the command above becomes the key for that piece
of information in the secret.

How the secret gets mounted is specified in `cronjob.yaml`:
- folder is `/secrets`, as set in
`spec.jobTemplate.spec.containers[].volumeMounts[].mountPath`
- filename is `my-mounted-secret.txt`, as set in
`spec.jobTemplate.spec.volumes[].secret.items[].path`






# 4. Do it all with a private container image

1. Make a new private repo on GitLab
   (we'll only use it for the container registry)
2. Make sure you're authenticated to gitlab in docker
   `docker login registry.gitlab.com`
   (will need to use a [Personal Access Token](https://gitlab.com/help/user/profile/personal_access_tokens))
3. Create a Deploy Token for the repo on GitLab
   (go to the repo -> Settings -> CI/CD -> Deploy Tokens);
   under "Scopes", check "read_registry"
4. create the secret in kubernetes
   (take care to enter your USERNAME and PASSWORD below)

        microk8s kubectl create secret docker-registry hello-py-private-gitlab-pull-secret --docker-server=registry.gitlab.com --docker-username=USERNAME --docker-password=PASSWORD --dry-run=client -o json | microk8s kubectl apply -f -
5. Note how the `hello-py-private-gitlab-pull-secret` is added
   in cronjob_private.yaml.




# Notes

## Debugging Stuff

To keep an eye on pods as they go up and down, use
`watch microk8s kubectl get pods`.
You can do the same thing with deployments, cronjobs etc.

To get details, use `microk8s kubectl describe SOMETHING`,
where something is the thing you want details on.

To get logs, use `microk8s kubectl logs PODNAME`.

To watch the logs live, use `microk8s kubectl logs --tail 200 -f PODNAME`.

To get a shell inside a running container, use
`microk8s kubectl exec -it deployment/api /bin/bash`.
NOTE: `bash` may not be available; use `sh` if it is not.

To keep an ephemeral container running so that you can get a shell in
(for instance for python scripts run by a CronJob), you could change
the command to execute, for example to `/bin/bash` or `sleep(10000)`.


## Deployments
Create a deployment:

    microk8s kubectl create -f deployment.yaml

You can delete it with `microk8s kubectl delete deployment hello-py`


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
sudo docker tag hello-py:latest localhost:5000/hello-py
```

3. Push it to a local registry:
```
sudo docker push localhost:5000/hello-py
```


## Resources

This was originally forked from https://github.com/rackbrainz/kubernetes-101,
which accompanies
[this series of Medium posts](https://medium.com/rackbrains/kubernetes-101-part-1-8bd033f3ff33).
