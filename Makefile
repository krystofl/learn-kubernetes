this_dir := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

# Tag for docker image (used in building, pushing, deployment)
tag := latest

# Docker Hub is the default registry, so this will go to
# https://hub.docker.com/repository/docker/krystofl/hello-py
registry    := krystofl/
app         := hello-py

private_registry:= registry.gitlab.com/krystofl/
private_app     := hello-py-private

# Text colors
TEXT_BOLD   := $(shell tput -Txterm bold)
TEXT_RED    := $(shell tput -Txterm setaf 1)
TEXT_GREEN  := $(shell tput -Txterm setaf 2)
TEXT_WHITE  := $(shell tput -Txterm setaf 7)
TEXT_YELLOW := $(shell tput -Txterm setaf 3)
TEXT_RESET  := $(shell tput -Txterm sgr0)

LG_ARROW := $(TEXT_BOLD)$(TEXT_GREEN)==>$(TEXT_RESET)
ARROW    := $(TEXT_YELLOW)->$(TEXT_RESET)

# And add help text after each target name starting with ##
# A category can be added with @category
HELP_FUN = \
	%help; \
	while(<>) { push @{$$help{$$2 // 'options'}}, [$$1, $$3] if /^([a-zA-Z\-]+)\s*:.*\#\#(?:@([a-zA-Z\-]+))?\s(.*)$$/ }; \
	print "usage: make [target] (option=value)\n\n"; \
	for (sort keys %help) { \
	print "${TEXT_WHITE}$$_:${TEXT_RESET}\n"; \
	for (@{$$help{$$_}}) { \
	$$sep = " " x (24 - length $$_->[0]); \
	print "  ${TEXT_YELLOW}$$_->[0]${TEXT_RESET}$$sep${TEXT_GREEN}$$_->[1]${TEXT_RESET}\n"; \
	}; \
	print "\n"; }

help: ##@Other Show this help.
	@perl -e '$(HELP_FUN)' $(MAKEFILE_LIST)


###########
## Build ##
###########

build_cmd := docker build -t $(registry)$(app):$(tag) .
.PHONY: build
build: ##@Build Build the hello-py image
	@echo "$(LG_ARROW) Building image $(registry)$(app):$(TEXT_RED)$(tag)$(TEXT_RESET)"
	$(build_cmd)

push_cmd := docker push $(registry)$(app):$(tag)
.PHONY: push
push: build ##@Build Build and push the hello-py image
	@echo "$(LG_ARROW) Pushing image $(registry)$(app):$(TEXT_RED)$(tag)$(TEXT_RESET)"
	$(push_cmd)

#############
## CronJob ##
#############
cronjob_cmd := microk8s kubectl create -f cronjob.yaml
.PHONY: cronjob
cronjob: ##@CronJob Create the CronJob from cronjob.yaml
	@echo "$(LG_ARROW) Deploying a CronJob from $(TEXT_RED)cronjob.yaml$(TEXT_RESET)"
	$(cronjob_cmd)

delete_cronjob_cmd := microk8s kubectl delete cronjob hello-py-cronjob
.PHONY: delete-cronjob
delete-cronjob: ##@CronJob Delete the CronJob from cronjob.yaml
	@echo "$(LG_ARROW) Deleting the CronJob from $(TEXT_RED)cronjob.yaml$(TEXT_RESET)"
	$(delete_cronjob_cmd)

secret_cmd := microk8s kubectl create secret generic my-secret --from-file=./secret.txt
.PHONY: secret
secret: ##@CronJob Create a secret from secret.txt
	@echo "$(LG_ARROW) Deleting the CronJob from $(TEXT_RED)secret.txt$(TEXT_RESET)"
	$(secret_cmd)


######################
## Private Registry ##
######################
gitlab-pull-secret-cmd := @read -p "Deploy Token Username: " USERNAME; \
													read -p "Deploy Token Password: " PASSWORD; \
													echo; \
													read -p "Registry URL [registry.gitlab.com]: " REGISTRY; \
													export REGISTRY=$${REGISTRY:-registry.gitlab.com}; \
													echo; \
													microk8s kubectl \
														create \
														secret \
														docker-registry \
														hello-py-private-gitlab-pull-secret \
														--docker-server=$$REGISTRY \
														--docker-username=$$USERNAME \
														--docker-password=$$PASSWORD \
														--dry-run=client \
														-o json | \
														microk8s kubectl \
																apply -f -
.PHONY: gitlab-pull-secret
gitlab-pull-secret: ##@Private-Registry Create a secret so that you can pull images from the PRIVATE registry.gitlab.com/krystofl/hello-py-private
	@echo "$(LG_ARROW) Generating the Gitlab Pull Secret"
	$(gitlab-pull-secret-cmd)

private-push-cmd := docker tag $(registry)$(app):$(tag) $(private_registry)$(private_app):$(tag); \
										docker push $(private_registry)$(private_app):$(tag)
.PHONY: private-push
private-push: build ##@Private-Registry Build and push the hello-py image to the PRIVATE registry
	@echo "$(LG_ARROW) Pushing image $(TEXT_RED)$(private_registry)$(private_app):$(tag)$(TEXT_RESET)"
	$(private-push-cmd)

private-cronjob-cmd := microk8s kubectl create -f cronjob_private.yaml
.PHONY: private-cronjob
private-cronjob: ##@Private-Registry Create a the CronJob from cronjob_private.yaml
	@echo "$(LG_ARROW) Deploying a CronJob from $(TEXT_RED)cronjob_private.yaml$(TEXT_RESET)"
	$(private-cronjob-cmd)

delete-private-cronjob-cmd := microk8s kubectl delete cronjob hello-py-private-cronjob
.PHONY: delete-private-cronjob
delete-private-cronjob: ##@Private-Registry Delete the CronJob from private_cronjob.yaml
	@echo "$(LG_ARROW) Deleting the CronJob from $(TEXT_RED)private_cronjob.yaml$(TEXT_RESET)"
	$(delete-private-cronjob-cmd)



#########
## Dev ##
#########

.PHONY: dev-shell
dev-shell: ##@Dev Run the hello-py image locally and open a shell
	@echo "$(LG_ARROW) Giving you a TTY for $(registry)$(app):$(tag)"
	@docker run --rm --name hello-py \
		--network host \
		-it $(registry)$(app):$(tag) /bin/bash

.PHONY: print-tag
print-tag: ##@Dev print the current tag / image version
	@echo "$(LG_ARROW) Current tag: $(registry)$(app):$(TEXT_RED)$(tag)$(TEXT_RESET)"
