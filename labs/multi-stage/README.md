---
title: Multi-Stage Builds
lang: en
slug: multi-stage
section: cicd
order: 4
duration: 40
requires: [docker]
status: updated
upstream: labs/multi-stage
---
# Multi-Stage Builds

Multi-stage builds use the standard Dockerfile syntax, with multiple stages separated with `FROM` commands. They give you a repeatable build with minimal dependencies.

You won't see multi-stage builds used everywhere, but they're a great way to centralize your toolset - developers and build servers just need Docker and the source code, all the tools come packaged in Docker images, so everyone's using the same versions.

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

- [Multi-stage build docs](https://docs.docker.com/develop/develop-images/multistage-build/)

<details>
  <summary>Sample Dockerfiles</summary>

It's the standard `docker build` command for multi-stage builds. The Dockerfile syntax uses multiple `FROM` instructions; the patterns are the same for all languages, but the individual details are specific.

These are samples in the major languages:

- [Java app using Maven build](https://github.com/sixeyed/widgetario/blob/main/src/products-api/java/Dockerfile)
- [Go application using Go modules](https://github.com/sixeyed/widgetario/blob/main/src/stock-api/golang/Dockerfile)
- [.NET Core app using Alpine images](https://github.com/sixeyed/widgetario/blob/main/src/web/dotnet/Dockerfile)

</details><br/>

## Multi-Stage Dockerfiles

We'll start with the *legacy* build engine, because it runs every stage in
order and that makes the structure of a multi-stage Dockerfile obvious. Then
we'll switch to BuildKit and compare:

```
# on macOS or Linux:
export DOCKER_BUILDKIT=0

# OR with PowerShell:
$env:DOCKER_BUILDKIT=0
```

> You'll see a warning: _"DEPRECATED: The legacy builder is deprecated and
> will be removed in a future release."_ That's expected. BuildKit has been
> the default since Docker 23 and the legacy builder is on its way out — we
> use it here for one build only, to see the contrast.

Here's a [simple multi-stage Dockerfile](./simple/Dockerfile):

- the `base` stage uses Alpine and simulates adding some dependencies
- the `build` stage builds on the base and simulates an app build
- the `test` stage starts from the build output and simulates automated testing
- the final stage starts from base and copies in the build output

📋 Build an image called `simple` from the `labs/multi-stage/simple` Dockerfile.

<details>
  <summary>Not sure how?</summary>

```
# just a normal build:
docker build -t simple ./labs/multi-stage/simple/
```

</details><br/>

> All the stages run, but the final app image only has content explicitly added from earlier stages.

Run a container from the image and it prints content from the base and build stages:

```
docker run simple
```

> The final image doesn't have the additional content from the test stage.

# BuildKit and build targets

BuildKit is Docker's build engine and the default since Docker 23. It's heavily optimized for multi-stage builds, running stages in parallel and skipping stages if the output isn't used.

Switch back to BuildKit by setting the environment variable (or just unsetting the one above):

```
# on macOS or Linux:
export DOCKER_BUILDKIT=1

# OR with PowerShell: 
$env:DOCKER_BUILDKIT=1
```

Now repeat the build for the simple Dockerfile - this time Docker will use BuildKit:

```
docker build -t simple:buildkit ./labs/multi-stage/simple/
```

> You'll see output from different stages at the same time - and if you look closely you'll see the test stage is skipped.

📋 Run a container from the new image. Is the output the same? Compare the image details.

<details>
  <summary>Not sure how?</summary>

```
# run a container - the output is the same:
docker run simple:buildkit

# list images - they're the same size but not the same image:
docker image ls simple
```

</details><br/>

BuildKit skips the test stage because none of the output is used in later stages. You can explicitly build an image up to a specific stage with the `target` flag:

```
docker build -t simple:test --target test ./labs/multi-stage/simple/
```

- `--target` states the target stage, Docker will build all stages up to and including the named one

> This image is the output of the test stage *not* the final stage.

📋 Run a container from the test build, printing the contents of the build.txt file.

<details>
  <summary>Not sure how?</summary>

```
# no output here - the test stage has no CMD instruction
docker run simple:test

# run the cat command to see the output
docker run simple:test cat /build.txt
```

</details><br/>

> The output is from the build stage plus the test stage.


## Simple Go application

Real multi-stage builds use an SDK (Software Development Kit) image to compile the app in the build stage and a smaller runtime image (with no build tools) to package the compiled app.

The images you use and the commands you run are different for each language, but you'll find [official images on Docker Hub for all the major platforms](https://hub.docker.com/search?q=&type=image&image_filter=official&category=languages), including:

- [maven](https://hub.docker.com/_/maven) and [gradle](https://hub.docker.com/_/gradle) to build Java apps - using [eclipse-temurin](https://hub.docker.com/_/eclipse-temurin) for the runtime image (Docker Hub's `openjdk` image is deprecated)
- [python](https://hub.docker.com/_/python) - has Pip installed for dependencies
- [node](https://hub.docker.com/_/node) for Node.js apps - this has NPM so you can install packages in the build stage
- [golang](https://hub.docker.com/_/golang) for Go apps - they don't need a runtime so the final image can start from [scratch](https://hub.docker.com/_/scratch)
- [dotnet/sdk](https://hub.docker.com/_/microsoft-dotnet-sdk/) for .NET apps, using [dotnet/runtime](https://hub.docker.com/_/microsoft-dotnet-runtime/) or [dotnet/aspnet](https://hub.docker.com/_/microsoft-dotnet-aspnet/) for the final app image

We won't cover different languages in detail. The [whoami Dockerfile](./whoami/Dockerfile) shows how the pattern works, using a Go application:

- the builder stages starts from the Go SDK image
- it installs the OS packages needed to build the app
- then it copies the library list (`go.mod`) and the lock file (`go.sum`) and
  runs `go mod download` to install the app's dependencies
- next it copies the source code and compiles the app
- the final app image sets up the container environment
- then it copies in the compiled output from the builder

📋 Build an image called `whoami` from the folder `labs/multi-stage/whoami`.

<details>
  <summary>Not sure how?</summary>

```
docker build -t whoami ./labs/multi-stage/whoami/
```

</details><br/>

> You'll see all the stage output from BuildKit.

SDK images are typically very large, having the whole build toolset. You don't want to use an SDK image in your final stage, otherwise you'll have all that stuff in your app image.

📋 Compare the sizes of the `whoami` and `golang` images.

<details>
  <summary>Not sure how?</summary>

```
docker pull ghcr.io/yasinoz/library/golang:1.27.2-alpine

docker image ls -f reference=whoami -f reference=golang
```

</details><br/>

> Woah! The SDK image is hundreds of megabytes; the app image is a few.
>
> Docker 29 splits the old `SIZE` column into `DISK USAGE` and `CONTENT SIZE`,
> so you'll see two numbers - the gap is just as big either way.


The app is a simple web server. Run a container publishing a random port and find the port:

```
docker run -d -P --name whoami1 whoami

docker port whoami1
```

> The `EXPOSE` instruction tells Docker the target port for the container; when you use the `-P` flag Docker publishes all exposed ports.

Now you can use the app:

```
curl localhost:<port>
```

> The server just prints some details about the environment and the request.

The container is running from a minimal image - there's nothing in the image which isn't necessary for the app to run. 

This helps minimize the attack surface of the application - try connecting to a shell session in the container:

```
# this will fail
docker exec -it whoami1 sh
```

There's no shell, so if an attacker compromised the application they'd have more work to do before they could launch an exploit.

## Lab

Apps need special Linux permissions to listen on the standard HTTP ports - even inside a container.

The whoami app supports an option to configure the port it listens on, so you can use a non-standard port and potentially run with tighter security.

Your goal for this lab is to run the whoami app in a container - using the `-port` application argument to listen on a specific port. What happens when you run a container with the `-P` (`--publish-all`) option? Does Docker map the new port correctly?

What do you need to do to run a working container?

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
