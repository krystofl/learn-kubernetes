# Learn Kubernetes

This repo is intended to work more as a reference than a tutorial.

The following assumes you have Docker installed and working
(and are logged into Docker Hub), and that you have a
[Microk8s](https://microk8s.io/#get-started) cluster working.

This repo shows how to accomplish some basic things with Kubernetes:
1. Run a Node.js Hello World app
2. Schedule a python script to run periodically with a CronJob
3. Work with a private image registry

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

## 1.1 Using an Image from a Remote Registry

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

The rest will use the files right here in the root of the repository.

There's also a Makefile to make it quicker to run the commands.
It will print out the exact command it's running each time.

There's a simple Hello World-type python script here.
Run it as `./hello.py`.

Build the image `make build`:

    docker build -t krystofl/hello-py:latest .

Push the image to Docker Hub `make push`:

    docker push krystofl/hello-py:latest


You should be able to see the image on
[Docker Hub](https://hub.docker.com/repository/docker/krystofl/hello-py).

Images tagged `latest` (as above) are unique in that if the
`imagePullPolicy` is not specified for an image, the value `Always`
is automatically applied (i.e. the image is pulled every time the pod is started).
See [the documentation](https://kubernetes.io/docs/concepts/configuration/overview/#container-images) for more info.

There's a
[secret](https://kubernetes.io/docs/concepts/configuration/secret/)
in `secret.txt`. To create the secret in Microk8s, run `make secret`:

    microk8s kubectl create secret generic my-secret --from-file=./secret.txt

The filename (`secret.txt`) in the command above becomes the key for that piece
of information in the secret.

How the secret gets mounted is specified in `cronjob.yaml`:
- folder is `/secrets`, as set in
`spec.jobTemplate.spec.containers[].volumeMounts[].mountPath`
- filename is `my-mounted-secret.txt`, as set in
`spec.jobTemplate.spec.volumes[].secret.items[].path`


Now create a CronJob from the script, set to run every minute `make cronjob`:

    microk8s kubectl create -f cronjob.yaml

Once a pod runs for the CronJob, you can check its logs with
`microk8s kubectl logs PODNAME`, where PODNAME is the name of the pod.



# 3. Using a Private Remote Registry

Now let's do it with a private registry. We'll use GitLab here.

1. Make a new private repo on GitLab
   (we'll only use it for the container registry)
2. Make sure you're authenticated to gitlab in docker
   `docker login registry.gitlab.com`
   (will need to use a [Personal Access Token](https://gitlab.com/help/user/profile/personal_access_tokens))
3. Create a Deploy Token for the repo on GitLab
   (go to the repo -> Settings -> CI/CD -> Deploy Tokens);
   under "Scopes", check "read_registry"
4. create the secret in Microk8s `make gitlab-pull-secret`:

        microk8s kubectl create secret docker-registry hello-py-private-gitlab-pull-secret --docker-server=registry.gitlab.com --docker-username=USERNAME --docker-password=PASSWORD --dry-run=client -o json | microk8s kubectl apply -f -

5. Note how the `hello-py-private-gitlab-pull-secret` is added
   in cronjob_private.yaml.

Schedule the cronjob `make private-cronjob`:

    microk8s kubectl create -f private_cronjob.yaml

You can view that it gets scheduled, logs, etc. as before.

To delete it, run `make delete-private-cronjob`:








# Notes & Resources

## Monitoring & Debugging Stuff

To keep an eye on things as they go up and down, use
`watch microk8s kubectl get all`.
You can also get just nodes, pods, or any other resource.

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

To get details of an unreachable node, you can try
`microk8s kubectl get node NODENAME -o yaml >OUTPUTFILE.yaml`


## Get a Terminal in a running Pod

In debugging, it's helpful to be able to get a terminal in a running pod.
To do that, you can create a pod that just sits there indefinitely:

    args :
    - tail
    - -f
    - /dev/null

Then get a terminal in it by running

    kubectl exec -it <PODNAME> bash


## Namespaces & Contexts

**[Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)**:
Kubernetes supports multiple virtual clusters backed by the same physical cluster.
These virtual clusters are called namespaces.

The documentation says that *"Namespaces are intended for use in environments with many users spread across multiple teams, or projects. For clusters with a few to tens of users, you should not need to create or think about namespaces at all. Start using namespaces when you need the features they provide."*

When working with multiple clusters, including virtual clusters aka Namespaces,
contexts are used to switch which cluster commands run on.
[Documentation for Working with Multiple Clusters](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/).

The cluster configs are saved in `~/.kube/config`.

To see available contexts:

    kubectl config get-contexts

To use a specific context:

    kubectl config use-context MY-CONTEXT-NAME

To see which context is currently used:

    kubectl config current-context


## Sealed Secrets

**Problem:** "I can manage all my K8s config in git, except Secrets."

**Solution:** Encrypt your Secret into a SealedSecret, which *is* safe
to store - even to a public repository.  The SealedSecret can be
decrypted only by the controller running in the target cluster and
nobody else (not even the original author) is able to obtain the
original Secret from the SealedSecret.

[SealedSecret Repo](https://github.com/bitnami-labs/sealed-secrets) -
it's not an official part of Kubernetes.

You can create a SealedSecret like so:

	kubectl \
		--context $(context) \
		--namespace $(namespace) \
		create \
		secret \
		docker-registry \
		MY-SECRET-NAME \
		--docker-server=$$REGISTRY \
		--docker-username=$$USERNAME \
		--docker-password=$$PASSWORD \
		--dry-run \
		-o json | \
	kubeseal \
		--controller-namespace sealed-secrets \
		> ENCRYPTED-SECRET-FILENAME.json

To then create a Kubernetes secret from the SealedSecret, use

    kubectl create -f ENCRYPTED-SECRET-FILENAME.json


### AppArmor Interference

**TL;DR: if the main node is stuck in `NotReady` status, reinstalling
        Microk8s could be the simplest solution.**

[AppArmor](https://gitlab.com/apparmor/apparmor/-/wikis/Documentation)
is a Linux Security Module implementation of name-based mandatory access controls.

Sometimes, it can block Microk8s processes from functioning properly.
This can manifest itself as 100% CPU usage after `microk8s start`, with
`apparmor_parser` using a ton of CPU resources as shown by running `top`.
Another way to notice this is the main node created by microk8s being stuck
in the `NotReady` status.

[Here is a guide](https://wiki.debian.org/AppArmor/HowToUse#Inspect_the_current_state)
in figuring out if AppArmor is messing with Microk8s.

List running executables which are currently confined by an AppArmor profile:

    ps auxZ | grep -v '^unconfined'

[This AskUbuntu answer](https://askubuntu.com/a/1144525) describes how to
disable AppArmor for a specific service.

To disable AppArmor for `containerd`:

    sudo ln -s /etc/apparmor.d/cri-containerd.apparmor.d /etc/apparmor.d/disable
    sudo apparmor_parser -R /etc/apparmor.d/cri-containerd.apparmor.d

That didn't work, or at least it didn't completely resolve the problem.

[This answer](https://askubuntu.com/a/491304) describes how to fiddle with
AppArmor settings using apparmor-utils.

    sudo apt install apparmor-utils

Ultimately, though, nothing worked... until I did a fresh install of
Microk8s, which worked like a charm.



# Resources

[Kubernetes Configuration Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

Working with local images in Microk8s:
1. [Using Microk8s's built-in registry](https://microk8s.io/docs/registry-built-in)
2. [Using the images without a registry](https://microk8s.io/docs/registry-images)
