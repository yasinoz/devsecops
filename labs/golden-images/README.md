---
title: Golden Image Libraries
lang: en
slug: golden-images
section: security
order: 3
duration: 50
requires: [docker]
status: needs-review
upstream: labs/golden-images
---
# Golden Image Libraries

Docker Hub is a great place to find open-source software, pre-packaged and ready to run. But anyone can push public images to Docker Hub so you can't necessarily trust what you find there. Official images can be trusted, but they're updated frequently and you need to keep on top of the updates.

Letting developers use any base image for their apps is not a good idea. They could unknowingly use a malicious image which has a backdoor opened, or is running a bitcoin miner. Requiring official images to be the base is a better policy, but you could end up with lots of versions and variations which costs efficiency and make it harder to secure your apps. 

Building your own set of base images - _golden images_ - and mandating that all apps need to use those is the best approach. It lets you curate your own approved list of images and tailor them as you need.

<!-- prereqs:auto -->
## Before you start

Takes about 50 minutes.

**Docker Desktop** must be running. Check it:

```
docker version
```

A `Server:` section in the output means you are ready. If you get an error
instead, start Docker Desktop and wait until the whale icon stops animating.

> Run every command from the **root of this repository** - the paths in this lab are written relative to it.

## Developer Free-For-All

Let's understand the problem first. These two Java apps use different base images and different build patterns:

- [app-1/Dockerfile](./apps/app-1/Dockerfile) - uses Amazon Corretto 8, a decade-old Java on an Amazon Linux base, and that same JDK is used for compiling *and* running the app

- [app-2/Dockerfile](./apps/app-2/Dockerfile) - uses Eclipse Temurin, with a multi-stage build using the JDK for compilation and the JRE at runtime; these are Debian-based images

> This lab originally used Docker Hub's `java` image for app-1. Both `java` and the `openjdk` image that replaced it have since been **deleted** from Docker Hub, so the original Dockerfile does not build at all any more. That is the argument for golden images in one line: pin your apps to somebody else's base image and they break when that image goes away.

Build both apps with Compose:

```
docker compose -f labs/golden-images/apps/docker-compose.yml build
```

📋 List out the new images and compare them. Inspect the layers - are the two Java apps making good use of the layer cache?

<details>
  <summary>Not sure how?</summary>

The image references both start with `courselabs/app` and use the `v1` tag so you can use that in a filter:

```
docker image ls "courselabs/app*:v1"
```

You'll see that app-2 is around 450MB and app-1 is over 550MB. app-1 is the
bigger image even though it is the simpler build - it keeps a whole JDK in the
runtime image, where app-2 ships only a JRE.

Layer count is not the interesting part here; whether the layers are *shared*
is. Print just the layer digests for each image:

```
docker inspect -f '{{range .RootFS.Layers}}{{println .}}{{end}}' courselabs/app-1:v1

docker inspect -f '{{range .RootFS.Layers}}{{println .}}{{end}}' courselabs/app-2:v1
```

Line the two lists up and you'll find they have nothing in common. The only
digest that appears in both is `sha256:5f70bf18...`, which is Docker's empty
placeholder layer - it carries no files, so it is no cache re-use at all.

</details>

These are both Java apps and need the same runtime, but their image hierarchies are completely divergent - a decade-old Amazon Linux JDK against a current Debian Temurin JRE. They share no real layers, so there's no re-use of the Docker layer cache - bad news for disk space and network bandwidth, even without considering the security of the images.

## A Golden Image Library

To build your own base library, you need to decide on the platforms and variants you want to support. You need to get a balance: you want a small number of golden images to keep it manageable and make best use of the cache, but you need to support your applications.

This library has two sets of images for Java apps:

- [JDK based on Debian](./library/java/debian/jdk/Dockerfile) and [JRE based on Debian](./library/java/debian/jre/Dockerfile). These build on the official Eclipse Temurin images, pinned to a Java release - but not to a specific OS release, because the official image doesn't offer that level of granularity

- [JDK based on Alpine](./library/java/alpine/jdk/Dockerfile) and [JRE based on Alpine](./library/java/alpine/jre/Dockerfile). These are fully versioned - an explicit Alpine release with an explicit OpenJDK apk version. The versions are build arguments so they're easy to bump. The trade-off is upkeep: when Alpine rebuilds the package the apk version string changes and you have to follow it. (That is exactly what broke the upstream version of this lab - it pinned a package from Alpine 3.15, which went end-of-life.)

- [library/docker-compose.yml](./library/docker-compose.yml) - has the build details for the library images and uses a custom naming convention

📋 Build the image library with Compose, making sure you download the latest versions of the images in the `FROM` lines.

<details>
  <summary>Not sure how?</summary>

```
docker compose -f ./labs/golden-images/library/docker-compose.yml build --pull
```

</details>

Check the sizes and tags of the new library images:

```
docker image ls "courselabs/java*"
```

The Alpine versions are smaller than the Debian variants - the numbers below are from one run, yours will differ as the base images change:

```
REPOSITORY        TAG                IMAGE ID       CREATED              SIZE
courselabs/java   jdk-26.10          dbe839e1d807   About a minute ago   271MB       
courselabs/java   jre-26.10          ad98b2279e7f   About a minute ago   184MB       
courselabs/java   jre-debian-26.10   79786bc38074   2 weeks ago          221MB       
courselabs/java   jdk-debian-26.10   0d6d8cde8cc0   2 weeks ago          422MB
```

Now we have a set of images we can mandate for Java applications - with Alpine being preferred, but Debian available for additional compatibility.

## Using Golden Images

Using the image library just means changing the `FROM` image in the application Dockerfiles, and while we're doing that we can fix them up to use the standard multi-stage build pattern:

- [app-1/Dockerfile.v2](./apps/app-1/Dockerfile.v2) and [app-2/Dockerfile.v2](./apps/app-2/Dockerfile.v2) - both use the library JDK and JRE images

- [apps/docker-compose-v2.yml](./apps/docker-compose-v2.yml) - builds the apps with the v2 Dockerfiles and a `v2` tag

Build the new versions:

```
docker compose -f labs/golden-images/apps/docker-compose-v2.yml build
```


📋 List out the v2 images and compare the layers. Are we using the cache now?

<details>
  <summary>Not sure how?</summary>

These images start with `courselabs/app` and use the `v2` tag so you can use that in a filter:

```
docker image ls "courselabs/app*:v2"
```

They're both around 340MB - the same size as the golden JRE image, to the megabyte. The application binaries are so small they don't add much to the base image.

Inspect the base image and application images to check the layer IDs:

```
docker inspect courselabs/java:jre-26.10

docker inspect courselabs/app-1:v2

docker inspect courselabs/app-2:v2
```

There are two layers in the JRE image - the Alpine layer plus the OpenJDK layer. The app-1 image reuses those layers and adds two more - one which creates the `/app` folder and one which adds the class file. The app-2 image also has four layers - sharing three with app-1, so only the final layer with the app binary is different.

</details>

In one run the original v1 app images took around 860MB of disk between them, because they share no layers. The v2 apps took about 185MB in total - the JRE image they both share. Your exact figures will differ; the ratio is the point.

> You can use a tool like [Anchore](https://anchore.com) in your build to check the base images in your Dockerfiles, so builds will fail if the base images are not from the library

## Image Cache

It's tricky to see how much space your images actually use because Docker reports the _virtual size_ - which is how much storage the image would need if it was the only image on your machine. 

The output of the image list doesn't make it clear how much layer sharing is happening:

```
docker image ls "courselabs/app*"
```

It seems you have 2x184MB for the v2 apps, but we know that it's mostly one set of shared layers.

The `docker system` commands let you see how much storage is really being used, and let you clear down unused data.

📋 Use system commands to see how much disk space your images are using, and to clean up the unused data.

<details>
  <summary>Not sure how?</summary>

Disk usage uses the same command as the Linux OS:

```
docker system df
```

You'll see how many images are stored, how much disk they're using, and how much can be reclaimed. _Reclaimable_ images are ones which aren't being used by any containers - you don't really want to remove all of those, because it means next time you run a container you'll need to pull the image again.

But you can safely prune unused space, which deletes any layers which are no longer referenced by images (these are called _dangling_):

```
docker system prune -f
```

</details>

You'll want to regularly prune your system if you build lots of images. A scheduled job to prune any build servers is a good idea too - you'll be surprised how quickly an active server can max out the disk with Docker image layers.

## Lab

We have another Java app which should use our golden image, and it has a couple of other issues:

- [app-3/Dockerfile](./apps/app-3/Dockerfile) - the image uses Maven for the build; we don't have a golden image for that, but it isn't used in the final app image, so that can stay as it is. The runtime image is yet another official Java variant rather than one from our library.

- [app-3/pom.xml](./apps/app-3/pom.xml) - in Maven the POM file lists out all of the dependencies the application uses. But the current setup doesn't explicitly use the latest versions of the libraries so we don't have a full audit trail.

The setup will give you a working image, but you can't tell from SCM which versions of the libraries are installed:

```
docker build -t app-3:v1 labs/golden-images/apps/app-3
```

Your goal is to fix up those files to use the golden JRE image for the runtime, and use the latest versions of the libraries - micrometer and the JAR plugin.

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
docker compose -f labs/golden-images/apps/docker-compose.yml down
docker compose -f ./labs/golden-images/library/docker-compose.yml down
docker compose -f labs/golden-images/apps/docker-compose-v2.yml down
```

> This removes only the containers this lab started. If you want
> a clean slate, `docker ps` will show anything still running.
