---
title: Building Apps with Compose
lang: en
slug: compose-build
section: cicd
order: 5
duration: 45
requires: [docker]
status: updated
upstream: labs/compose-build
---
# Building Apps with Compose

Docker Compose models can include build-time details, so you can build multiple container images using one Docker Compose command. Using override files lets you customize the image references and set labels to track the image back to the source code.

<!-- outcomes:auto -->
## Why this lab matters

A real application is several images, and they have to be built the same way every time - on your laptop and on the build server. Compose lets one file describe all of them, and override files let the same definition produce a dev build and a release build without copy-pasting.

**After this lab you will be able to:**

- build every image in an application with one command
- pass build arguments and attach labels that trace an image back to its source commit
- layer override files to get different image tags from one build definition
- explain why CI builds and local builds should share the same Compose files
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

Takes about 45 minutes.

**Docker Desktop** must be running. Check it:

```
docker version
```

A `Server:` section in the output means you are ready. If you get an error
instead, start Docker Desktop and wait until the whale icon stops animating.

> Run every command from the **root of this repository** - the paths in this lab are written relative to it.

## Reference

- [Compose build spec](https://docs.docker.com/reference/compose-file/build/)

- [Using environment variables in Compose files](https://docs.docker.com/compose/how-tos/environment-variables/) 

<details>
  <summary>CLI overview</summary>

Docker Compose has commands to work with images:

```
docker compose build --help

docker compose push --help
```

> These support multiple YAML files in the same way as the other commands.

</details><br/>

## Building with Compose

All the source code for the random number app we've been using is in the `rng` folder, along with the Dockerfile and a Compose file: 

- [rng/docker-compose.yml](./rng/docker-compose.yml) - includes the context and Dockerfile paths

All paths in Compose are relative to the location of the Compose file. 

📋 Switch to the `rng` folder and build the images.

<details>
  <summary>Not sure how?</summary>

```
cd labs/compose-build/rng

docker compose build 
```

</details><br/>

> The build command builds all the images with a `build` section in the spec. You'll see the output from your configured build engine - you can use the original or BuildKit for this lab

These images have the tag `21.05-local`. You can use the same Compose file to run the app from your local images.

📋 Run the app using your new images and test it works.

<details>
  <summary>Not sure how?</summary>

```
docker compose up -d

# try the app at http://localhost:8090
```

</details><br/>

> The Compose spec has all the details to run and build the app. 

## Build arguments and image labels

A single Compose file to build and run your app is very appealing, but run and build options are very different and it's usually easier to split them to keep your Compose specs easier to read and maintain:

- [core.yml](./rng/core.yml) - defines the core services and networks for the random number app

- [build.yml](./rng/build.yml) - defines the build options for the services, including the path to the build context and the path to the Dockerfile

And with some additional config you can add some useful auditing to your images:

- the [rng API Dockerfile](./rng/docker/api/Dockerfile) uses `ARG` instructions - which are values you can set as build arguments - to add metadata to the image, using labels to record the build version and Git commit ID 

- [args.yml](./rng/args.yml) overrides the image name and sets default values for the build arguments. All the `${VARIABLES}`  can be overridden by environment variables on the machine running the build.

📋 Join all those files to build the app, then inspect the labels for the API image.

<details>
  <summary>Not sure how?</summary>

```
# join all the files to get the full build spec:
docker compose -f core.yml -f build.yml -f args.yml build

# this output shows label values:
docker image inspect --format '{{.Config.Labels}}' courselabs/rng-api:21.05-0
```

</details><br/>

> The default values from the Compose file set the label values.

You can set environment variables on your machine which will override the defaults in the Compose files:

```
# macOS or Linux:
export RELEASE=2021.07
export BUILD_NUMBER=121

# OR with PowerShell:
$env:RELEASE='2021.07'
$env:BUILD_NUMBER='121'
```

📋 Repeat the build. What are the new image tags? And the label values in the API image?

<details>
  <summary>Not sure how?</summary>

```
# it's the same set of files:
docker compose -f core.yml -f build.yml -f args.yml build

# the tag is 2021.07-121

# show the new label values:
docker image inspect --format '{{.Config.Labels}}' courselabs/rng-api:2021.07-121
```

</details><br/>

> Different build argument values break the cache for this build, so you'll see the Dockerfile instructions being run again.

Those labels values aren't very useful when you build locally - but in a Continuous Integration build, they would be set with the correct values by the build service.

## Docker Compose for CI builds

Compose is great for running lots of non-production environments on a single machine, but if you're not planning to use it for that the build feature is perfect for Continuous Integration. You can easily build your apps in Jenkins or GitHub Actions just by running `docker compose build`.

This repo also has a GitHub Actions workflow to build the RNG images using the same Docker Compose files you've been using locally:

- [rng-build.yml](./github/rng-build.yml) - GitHub workflows use a YAML spec, but if you're not familiar with them you'll see the same `docker compose` commands being executed.

The real images are in a public repo so you can browse to the workflow output:

https://github.com/courselabs/docker/actions/workflows/rng-build.yml

📋 Drill down into the latest build output and you'll see an image tag being pushed. Pull that image and inspect the labels.

<details>
  <summary>Not sure how?</summary>

```
# the build version is appended to the image tag, e.g for build 39:
docker pull ghcr.io/yasinoz/courselabs/rng-api:21.05-39

docker image inspect ghcr.io/yasinoz/courselabs/rng-api:21.05-39
```

</details><br/>

You'll see the actual build details stored in the image labels, something like this:

```
"Labels": {
  "build_tag": "RNG App Docker Image Weekly Build-33-refs/heads/main",
  "commit_sha": "dcd4b265f1406182a2e671b574af44100dbdfdab"
}
```

> This is from the same Dockerfiles and Compose files you use for a local build.

Image labels help you track back from a running container to the build pipeline which created it, and the exact version of the source code.

## Lab

Look closely at the GitHub workflow and you'll see it runs two sets of builds and pushes - the second set uses one more Compose override file.

What is the difference when you use the extra Compose file and why does the workflow run this second build?

Pull the API image from the tag in the second build and check if it's the same as the tag `21.05-39`.

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

Clean up by removing this lab's containers:

```
docker compose -f core.yml down
```

> This removes only the containers this lab started. If you want
> a clean slate, `docker ps` will show anything still running.

And if you're not in the `devsecops` root directory, change back to it:

```
cd ../../..

pwd

# make sure you're in the `devsecops` folder
```
