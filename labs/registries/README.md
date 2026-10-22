---
title: Accessing Images on Registries
lang: en
slug: registries
section: cicd
order: 3
duration: 30
requires: [docker]
status: updated
upstream: labs/registries
---

# Accessing Images on Registries

*Registries* are servers which store Docker images. Docker Hub is the most popular, but the registry API is standard and you can run your own registry in the cloud or locally as your private image store.

Organizations run their own registries so they can have a long-term store of release versions from the build pipeline, or to make images available in the same network region as the production environment.

<!-- orientation:auto -->
## How this lab works

Read this once - every lab in this track follows the same rules.

**Where you type the commands.** Open a terminal and go to the folder where you
cloned this repository. On Windows use **PowerShell** (search for it in the
Start menu), on macOS or Linux use **Terminal**. Every path in this lab is
written from the repository root, so stay there unless a step says otherwise.

**Lines starting with `>` are explanations, not commands.** Don't paste them.
Only the text inside grey code boxes gets typed.

**The 📋 sign means it's your turn.** When you see it, try the step yourself
first. Underneath it there is a collapsed **"Not sure how?"** arrow with the
answer - open it *after* you have tried, not before. The labs are written this
way on purpose: you remember what you worked out, not what you pasted.

**If a command fails, that is normal.** Some steps fail deliberately to show
you what the error looks like. Read the sentence above the command before you
assume something is broken.

**When you get stuck**, in this order:

1. Re-read the paragraph above the command - the answer is usually there.
2. Open the **"Not sure how?"** arrow.
3. Open `hints.md` for a nudge.
4. Open `solution.md` for the full answer. Using it is fine; copying it without
   reading is not.

**When you finish**, run the **Cleanup** section at the bottom. Labs share
ports and container names, so leftovers from one lab break the next one.
<!-- /orientation:auto -->

<!-- prereqs:auto -->
## Before you start

Takes about 30 minutes.

**Docker Desktop** must be running. Check it:

```
docker version
```

A `Server:` section in the output means you are ready. If you get an error
instead, start Docker Desktop and wait until the whale icon stops animating.

> Run every command from the **root of this repository** - the paths in this lab are written relative to it.

## Reference

- [Pulling images](https://docs.docker.com/engine/reference/commandline/image_pull/)
- [Pushing images](https://docs.docker.com/engine/reference/commandline/image_push/)
- [Registry API spec](https://github.com/opencontainers/distribution-spec/blob/main/spec.md#endpoints)
- [Docker Registry](https://docs.docker.com/registry/) - for running your own registry in a container :)

<details>
  <summary>CLI overview</summary>

It's still `image` commands to work with registries. The most popular commands have aliases:

```
docker image --help

docker pull --help

docker push --help

docker tag --help
```

</details><br/>


## Pushing images

Any images you build are only stored on your machine.

To share images you need to push them to a *registry* - like Docker Hub. For Docker Hub the image name needs to include your username, which Docker Hub uses to identify ownership.

Make sure you've [registered on Docker Hub](https://hub.docker.com/signup/). Then save your Docker ID in a variable, so we can use it in later commands:

```
# on Linux or macOS:
dockerId='<your-docker-hub-id>'

# OR with PowerShell:
$dockerId='<your-docker-hub-id>'
```

> This is your Hub username *not* your email address. For mine I use: `$dockerId='sixeyed'`

Now you can build an image, including your Docker ID in the  name:

```
docker build -t ${dockerId}/curl:26.10 -f labs/images/curl/Dockerfile.v2 labs/images/curl

docker image ls '*/curl'
```

📋 Now push your own `curl:26.10` image to Docker Hub.

<details>
  <summary>Not sure how?</summary>

```
# log in if you haven't already:
docker login -u ${dockerId}

# push your image:
docker push ${dockerId}/curl:26.10
```

</details><br/>

Docker Hub images are publicly available (you can create private images too). Run this command and browse to your image on Docker Hub:

```
echo "https://hub.docker.com/r/${dockerId}/curl/tags"
```

## Tags and references

Image names (properly called *references*) are built from three parts:

- the domain of the container registry
- the repository name - which identifies the app and the owner
- the tag - which can be anything but is usually used for versioning

A single image can have multiple references, which are like aliases - they're not copies of the image, they're different names for the same image.

Tags are typically used for versioning, so you can assume that `sixeyed/curl:26.09` and `sixeyed/curl:26.10` are different versions of the same app, published by the same owner.

Add a new reference for your image using the `tag` command:

```
docker tag ${dockerId}/curl:26.10 ${dockerId}/curl:26.11

docker image ls '*/curl'
```

> Now you have lots of curl images, but all the aliases have the same image ID

📋 Push all of your `curl` image tags to Docker Hub.

<details>
  <summary>Not sure how?</summary>

```
# you can push individual tags:
docker push ${dockerId}/curl:26.11

# or all local tags for the repository:
docker push --all-tags ${dockerId}/curl
```

</details><br/>

> You'll see lots of `Layer already exists` output - registries have the same layer caching approach as the Docker Engine.

## Running a local registry

Docker images for real apps can be big - hundreds of megabytes or even gigabytes. Downloading large images adds to the startup time for containers, so organizations typically run their own registry in the cloud or the datacenter.

All registries work in the same way, so they're pretty much interchangeable. You'd use [Azure Container Registry](https://azure.microsoft.com/en-gb/services/container-registry/) or [Amazon Elastic Container Registry](https://aws.amazon.com/ecr/) if you were running on Azure or AWS. 

In a local environment you can host your own registry, running in a container, using the official [Docker Registry](https://hub.docker.com/_/registry) image:

```
docker run -d -p 5000:5000 --name registry registry:3.1.2

docker logs registry
```

Your local registry domain is `localhost:5000` so you can include that in image references to push and pull locally.

The full image reference format is:

- `[registry-domain]/[repository-name]:[tag]`

📋 Tag the Alpine image and push it to your local registry.

<details>
  <summary>Not sure how?</summary>

```
# the tag command creates an alias, which can include the registry domain:
docker tag alpine localhost:5000/alpine

# pushing a tag with a domain in the reference tells Docker which registry to use:
docker push localhost:5000/alpine
```

</details><br/>

> Docker Desktop is configured to allow `localhost` registries, but not all Docker setups have that. If you get an error when you push, you need to [allow insecure registries](https://docs.docker.com/registry/insecure/#deploy-a-plain-http-registry).

The open-source registry doesn't have a web UI like Docker Hub, but you can work with it using the REST API:

```
curl --head localhost:5000/v2/

curl localhost:5000/v2/alpine/tags/list
```

> Every image has a tag - if you don't supply one, Docker uses a default.

You can remove your local image and pull it again from the registry:

```
docker image rm localhost:5000/alpine

docker pull localhost:5000/alpine
```

📋 Create and push some more tags for the Alpine image - check they're available in the registry.

<details>
  <summary>Not sure how?</summary>

```
# you can use any string in the image tag:
docker tag alpine localhost:5000/alpine:26.11

docker tag alpine localhost:5000/alpine:local

docker push --all-tags localhost:5000/alpine

curl localhost:5000/v2/alpine/tags/list
```

</details><br/>

> You should see the default tag and your new tags returned.

## Lab

Image references have enough detail for Docker to find the registry, and identify a specific version of the application. 

Docker uses defaults for the registry and the tag. What are those defaults? What is the full reference for the image `kiamol/ch05-pi`?

Not all official images are on Docker Hub. Microsoft uses its own image registry *MCR* at `mcr.microsoft.com`. What command would you use to pull version `10.0` of the `dotnet/runtime` image from MCR?

> Stuck? Try [hints](hints.md) or check the [solution](solution.md).
___
<!-- troubleshooting:auto -->
## If something goes wrong

**`Cannot connect to the Docker daemon`** - Docker Desktop is not running.
Start it and wait until the whale icon stops animating.

**`port is already allocated`** - a container from an earlier lab is still
holding that port. See what is running with `docker ps`, then remove the old
container with `docker rm -f <name>`.

**`The container name "/..." is already in use`** - same cause, same fix:
`docker rm -f <name>`, then run the command again.

**`unable to prepare context: path ... not found`** on a build - you are in the
wrong folder. Every command in this lab assumes you are at the root of this
repository.

**A `docker run` that prints usage text instead of working** - some commands in
this lab are meant to fail, to show you what a wrong argument looks like. Read
the text around the command before assuming it is broken.

Still stuck? The **Cleanup** section below resets everything, so you can start
the lab again from a clean machine.


## Cleanup

Cleanup by removing all containers:

```
docker rm -f $(docker ps -aq)
```

> On **PowerShell** the command substitution syntax is different:
>
> ```
> docker rm -f @(docker ps -aq)
> ```
>
> ⚠️ Either version removes **every** container on your machine, not just the
> ones from this lab. Run `docker ps` first if you have other work running.
