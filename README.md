# Learn Kubernetes

Krystof learns Kubernetes.

The following assumes you have Docker installed and working
(and are logged into Docker Hub), and that you have a
[Microk8s](https://microk8s.io/#get-started) cluster working.

**Goals:**
1. Build a simple Hello World python container image
2. Push the image to a repository
3. Deploy it as a CronJob to a local Microk8s cluster
   - 3.1. Provide a secret to the container
   - 3.2. Mount a volume (TODO)
5. Same 1-4 above, but now with a private image (TODO)

**Questions & TODOs:**
- divide this up into separate examples:
  - 1. node.js app
  - 2. python cronjob with secret
  - 3. add namespaces (and contexts) and a Makefile to automate things
  - 4. add local hostname volume.
  - 5. add Kustomize or Helm
- remaining TODOs from above

To keep an eye on pods as they go up and down, use
`watch microk8s kubectl get pods`.
You can do the same thing with deployments, cronjobs etc.



# 1. A Node.js Hello World App

This was originally forked from https://github.com/rackbrainz/kubernetes-101,
which accompanies
[this series of Medium posts](https://medium.com/rackbrains/kubernetes-101-part-1-8bd033f3ff33).

`cd 01-node-js`

It's a simple Hello-World app in Node.js. To test that the app works,
run it with `node index.js` and go to `localhost:3000` in a web browser.

Build the container image:

    docker build -t krystofl/hello-node:v1 .

Now we need to create deployment of the image. We have two options:
1. use the pre-built image from Docker Hub
2. use the image we just built (and which is local to our computer)

## 1.1 - Using an Image from a Remote Registry

Push the locally-created image to Docker Hub:

    docker push krystofl/hello-node:v1

Create a deployment:

    microk8s kubectl create -f deployment-remote.yaml

Set up port-forwarding so that we can talk to the app
(fill in the PODNAME below; you can get it from `microk8s kubectl get pods`):

    microk8s kubectl port-forward PODNAME 3000:3000

You should now see the app at localhost:3000.
Delete the deployment when you are done:

    microk8s kubectl delete deployment hello-node


## 1.2. Using the local image

This is somewhat tricky with Microk8s, but there should be two options:
1. [Using Microk8s's built-in registry](https://microk8s.io/docs/registry-built-in)
2. [Using the images without a registry](https://microk8s.io/docs/registry-images)

Note that for approach 2 above, the `latest` tag CANNOT be used
(this trick relies on caching, and Kubernetes does not look in cache for images
 tagged `latest`).



# 2. Python CronJob

incl. Makefile
figure out the using a local image (see two options above)


# 3. Using a Private Remote Registry

TODO






# 1. Build a Container Image

The repo contains a very simple python "Hello World" application.

To create a container from it, run

    docker build -t hello-py:latest .

Images tagged `latest` (as above) are unique in that if the
`imagePullPolicy` is not specified for an image, the value `Always`
is automatically applied (i.e. the image is pulled every time the pod is started).
See [the documentation](https://kubernetes.io/docs/concepts/configuration/overview/#container-images) for more info.



# 2. Push the image to a repository

Need to be logged in to Docker Hub.

In this case to docker hub @ `krystofl/hello-py`
(adapted from https://stackoverflow.com/a/58633144)

    docker tag hello-py:latest krystofl/hello-py:latest
    docker push krystofl/hello-py:latest

You should be able to see the image on
[Docker Hub](https://hub.docker.com/repository/docker/krystofl/hello-py).



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




# Notes & Resources

Take a look at the
[Kubernetes Configuration Best Practices Here](https://kubernetes.io/docs/concepts/configuration/overview/)

## Monitoring & Debugging Stuff

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


# Resources

Working with local images in Microk8s without a local registry:
https://microk8s.io/docs/registry-images

**Does not work with the `latest` tag!**
