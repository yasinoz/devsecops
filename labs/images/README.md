---
title: Building Container Images
lang: en
slug: images
section: cicd
order: 1
duration: 40
requires: [docker]
status: updated
upstream: labs/images
---
# Building Container Images

*Images* are the packages which containers run from. You'll build an image for each component of your application, and the image has all the pre-requisites installed and configured, ready to run.

You can think of images as the filesystem for the container, plus some metadata which tells Docker which command to run when the container starts.

<!-- outcomes:auto -->
## Why this lab matters

Every container starts from an image, so the image is where your app's dependencies, configuration and attack surface are decided. Getting this wrong is expensive later: a bloated base image means slow deployments and hundreds of CVEs you inherited without asking.

**After this lab you will be able to:**

- write a Dockerfile and build an image from it
- explain the difference between `CMD` and `ENTRYPOINT`, and when each one gets in your way
- read an image's layers and say why two images with identical contents can have different IDs
- argue for pinning a version tag instead of `latest`
<!-- /outcomes:auto -->

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

Takes about 40 minutes.

**Docker Desktop** must be running. Check it:

```
docker version
```

A `Server:` section in the output means you are ready. If you get an error
instead, start Docker Desktop and wait until the whale icon stops animating.

> Run every command from the **root of this repository** - the paths in this lab are written relative to it.

## Reference

- [Dockerfile syntax](https://docs.docker.com/engine/reference/builder/)
- [Image build command](https://docs.docker.com/engine/reference/commandline/image_build/)


<details>
  <summary>CLI overview</summary>

You use the `image` commands to work with images. The build command also has aliases:

```
docker image --help

docker build --help

docker history --help
```

</details><br/>


## Base images

Images can be built in a hierarchy - you may start with an OS image which sets up a particular Linux distro, then build on top of that to add your application runtime.

Before we build any images, let's make the build output verbose so you can
see every Dockerfile instruction as it runs:

```
# on macOS or Linux:
export BUILDKIT_PROGRESS=plain

# OR with PowerShell:
$env:BUILDKIT_PROGRESS='plain'
```

> [BuildKit](https://docs.docker.com/build/buildkit/) is Docker's build engine
> and has been the default since Docker 23. By default it collapses the output
> into a tidy summary, which hides the individual instructions. Setting
> `BUILDKIT_PROGRESS=plain` prints every step, which is what you want while
> you're learning the Dockerfile syntax.

We'll build a really simple base image:

- [base image Dockerfile](./base/Dockerfile)

```
docker build -t courselabs/base ./labs/images/base
```

- `-t` or `--tag` gives the image a name
- you end the build command with the path to the Dockerfile folder


📋 List all the images you have - then filter them for images starting with 'courselabs'.

<details>
  <summary>Not sure how?</summary>

```
# list all local images:
docker image ls

# and filter for the courselabs images:
docker image ls 'courselabs/*'
```

</details><br/>

> These are the images stored in your local Docker engine cache.

The new base image doesn't add anything to the [official Ubuntu image](https://hub.docker.com/_/ubuntu), which is available in lots of different [versions](https://hub.docker.com/_/ubuntu?tab=tags&page=1&ordering=last_updated).


📋 Pull the main Ubuntu image, then pull the image for Ubuntu version 24.04.


<details>
  <summary>Not sure how?</summary>

```
docker pull ubuntu

# image versions are set in the tag name:
docker pull ghcr.io/yasinoz/library/ubuntu:24.04
```

</details><br/>

List all your Ubuntu images and your own base image:

```
docker image ls --filter reference=ubuntu --filter reference='ghcr.io/yasinoz/library/ubuntu' --filter reference=courselabs/base
```

> Look at the IDs - all three are different. `ghcr.io/yasinoz/library/ubuntu:24.04` is a genuinely
> different image: a different Ubuntu release. `courselabs/base` is the subtle
> one. Its Dockerfile adds nothing at all to `ghcr.io/yasinoz/library/ubuntu:26.04` (which is what
> `latest` currently points to), but BuildKit exports a new image for every
> build, so the result gets an ID of its own.
>
> The *contents* are identical though - compare the layers:
>
> ```
> docker image inspect courselabs/base --format '{{.RootFS.Layers}}'
>
> docker image inspect ubuntu --format '{{.RootFS.Layers}}'
> ```
>
> Same layer IDs, different image ID. That's the lesson twice over: images
> share layers, and pinning a version matters because `latest` moves while a
> version tag doesn't.

## Commands and entrypoints

The Dockerfile syntax is straightforward to learn:

- every image needs to start `FROM` another image
- you use `RUN` to execute commands as part of the build
- and `CMD` sets the command to run when the container starts

Here's a simple example which installs the curl tool:

- [curl Dockerfile](./curl/Dockerfile)

📋 Build an image called `courselabs/curl` from the `labs/images/curl` Dockerfile.

<details>
  <summary>Not sure how?</summary>

```
docker build -t courselabs/curl ./labs/images/curl
```

</details><br/>

Now you can run a container from the image, but it might not behave as you expect:

```
# just runs curl:
docker run courselabs/curl 

# doesn't pass the URL to curl:
docker run courselabs/curl docker.courselabs.co

# to use curl you need to specify the curl command:
docker run courselabs/curl curl --head docker.courselabs.co
```

> The `CMD` instruction sets the exact command for a container to run. You can't pass options to the container command - but you can override it completely.

This updated Dockerfile makes a more usable image:

- [curl Dockerfile - v2](./curl/Dockerfile.v2)

Build a v2 image from that Dockerfile:

```
docker build -t courselabs/curl:v2 -f labs/images/curl/Dockerfile.v2 labs/images/curl
```

- the `-f` flag specifies the Dockerfile name - you need it if you're not using the standard name

You can run containers from this image with more logical syntax:

```
docker run courselabs/curl:v2 --head docker.courselabs.co
```

> The `--head` argument and URL in the container command gets passed to the entrypoint

📋 List all the `courselabs/curl` images to compare sizes.

<details>
  <summary>Not sure how?</summary>

```
docker image ls courselabs/curl
```

</details><br/>

> The v2 image is smaller - which means it has less stuff in the filesystem and a smaller attack surface.


## Image hierarchy

You don't typically use OS images as the base in your `FROM` image. You want to get as many of your app's pre-requisites already installed for you.

You should use [official images](https://hub.docker.com/search?q=&type=image&image_filter=official&category=languages), which are application and runtime images which are maintained by the project teams.

This Dockerfile bundles some custom HTML content on top of the official Nginx image:

- [web Dockerfile](./web/Dockerfile)
- [custom HTML page](./web/index.html)

```
docker build -t courselabs/web ./labs/images/web --pull
```

> The `pull` argument tells Docker to download the latest version of the FROM image before it starts the build.

- the folder path is called the *context* - it contains the Dockerfile and any files it references, the `index.html` file in this case

📋 Run a container from your new image, publishing port 80, and browse to it.

<details>
  <summary>Not sure how?</summary>

```
# use any free local port, e.g. 8090:
docker run -d -p 8090:80 courselabs/web

curl localhost:8090
```

</details><br/>

> The container serves your HTML document, using the Nginx setup configured in the official image 

Docker images are composed of _layers_. An image is one logical package, but it's physically stored as multiple small files, which are the layers. 

Layers are read-only and they can be shared between images - if you build your images correctly you'll get very efficient use of disk space and network bandwidth.

Inspect your web image and you'll see the layer IDs at the end of the output:

```
docker inspect courselabs/web
```

📋 Inspect the image which your web image is based from. Do they have any shared layers? How about the image *that* image is based on?

<details>
  <summary>Not sure how?</summary>

The base image is Nginx running on Alpine:

```
docker pull ghcr.io/yasinoz/library/nginx:1.31.7-alpine

docker inspect ghcr.io/yasinoz/library/nginx:1.31.7-alpine
```

And you can check Alpine too:

```
docker pull ghcr.io/yasinoz/library/alpine:3.24

docker inspect ghcr.io/yasinoz/library/alpine:3.24
```

</details><br/>

> You can see all the shared layers - the web image builds on top of the Nginx layers, and the Nginx image builds on top of the Alpine layers.

Here's the full image hierarchy:

```
ghcr.io/yasinoz/library/alpine:3.24
└─ ghcr.io/yasinoz/library/nginx:1.31.7-alpine
    └─ courselabs/web 
```

Some images include the full audit in their tag - e.g. `golang:1.17.3-alpine3.15`. The Nginx tag doesn't include the Alpine OS version, so you need to figure that out by trial and error (or knowing which OS version was current when the image was built).

## Lab

Your turn to write a Dockerfile. 

There's a simple Java app in this folder which has already been compiled into the file `labs/images/java/HelloWorld.class`.

Build a Docker image which packages that app, and run a container to confirm it's working. The command your container needs to run is `java HelloWorld`.

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
