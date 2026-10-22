---
title: Security Scanning
lang: en
slug: scanning
section: security
order: 2
duration: 45
requires: [docker]
status: updated
upstream: labs/scanning
---
# Security Scanning

Scanners inspect the binaries in a filesystem or a container image, looking for known vulnerabilities. They typically use multiple databases to determine what application the binary is from, what version of the app and whether there are any CVEs (Common Vulnerabilities and Exposures) for that version.

There are several tools for scanning container images - [Clair](https://quay.github.io/clair/) and [Snyk](https://snyk.io) are popular options. We'll be using [Trivy](https://trivy.dev/latest/docs/) which is free, open source and runs in containers, so it can be integrated nicely into a pipeline. Trivy can scan the binaries in container images, and also run static analysis on Dockerfiles and Kubernetes manifests. 

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

## References

- [Trivy documentation](https://trivy.dev/latest/docs/)

- [Trivy on GitHub](https://github.com/aquasecurity/trivy) 

- [Trivy policies for misconfiguration](https://trivy.dev/latest/docs/misconfiguration/policy/builtin/)

- [Trivy in the CNCF DevSecOps radar](https://radar.cncf.io/2021-09-devsecops)

## Image Scanning with Trivy

Trivy is a command line tool, but we don't need to install it on our machines, we can use the [Docker image](https://hub.docker.com/r/aquasec/trivy) published by Aqua Security, who maintain Trivy.

Run a Trivy container - this [Docker Compose file](./docker-compose.yml) mounts your local repo folder mounted into the container filesystem, so Trivy can see those files:

```
docker compose -f labs/scanning/docker-compose.yml run trivy
```

You're connected to the Trivy container. Check the commands you can run, and then scan an image on Docker Hub:

```
trivy

trivy image ghcr.io/yasinoz/sixeyed/whoami:24.07
```

> On the first run Trivy will download the vulnerabilities database, which can take a minute or two

No vulnerabilities in this image - that's because it's built `FROM scratch` and the only binaries are the app and a couple of dependencies.

📋 Scan the image `python:3.4-alpine` on Docker Hub. How does it look?

<details>
  <summary>Not sure ?</summary>

Run: 

```
trivy image python:3.4-alpine
```

</details>

Lots of issues here, including high and critical severities. One of them is this [buffer over-read vulnerability](https://avd.aquasec.com/nvd/cve-2019-15903) which doesn't sound good.

> This is an official image, but Python 3.4 went end-of-life in 2019 - the image is a decade old. Official images aren't removed from Docker Hub when new versions are released, because that would break people's builds; keeping your dependencies current is your responsibility, not the registry's.

This Trivy container is set up to talk to your local Docker Engine, so you can scan your own images as well as those on Docker Hub.

**Open another terminal** and build a website image from [this Dockerfile](./web/Dockerfile) which uses a very old version of Nginx:

```
docker build -t courselabs/web:nginx-1.14 ./labs/scanning/web
```

📋 Scan your newly built image in Trivy. Is it good to go live?

<details>
  <summary>Not sure ?</summary>

Trivy can use your local Docker Engine so it has access to your image cache:

```
trivy image courselabs/web:nginx-1.14
```

You'll see lots of errors - so many on my run that it scrolls past the terminal buffer.

Try this to just print critical issues:

```
trivy image -s CRITICAL courselabs/web:nginx-1.14
```

You'll see 40+ critical errors...

</details>

> Image scanning is good to include in your pipeline after images have been built - it will find issues in the OS tools as well as any libraries your application uses.

## Library Scanning

Trivy can also scan source code folders, but it doesn't analyse your code (which is what SonarQube does in the [static analysis lab](../static-analysis/README.md)). Trivy looks for library lists (e.g. `package-lock.json` for Node.js apps) and it scans each library for CVEs.

📋 Try scanning the Python dependencies in `/labs/scanning/python`

<details>
  <summary>Not sure how?</summary>

```
trivy filesystem /labs/scanning/python/
```

Lots again. The options are consistent for different types of scan, so you can limit to critical issues:

```
trivy filesystem -s CRITICAL /labs/scanning/python/
```

</details>

You can also scan public Git repos. This scans the repo for my Kubernetes book which includes lots of demo apps:

```
trivy repository https://github.com/sixeyed/kiamol
```

You'll see findings in the application dependencies - which ones depends on when you run it, because Trivy's database is updated constantly and the repo changes too. That is the point: a scan is a snapshot of what is known today.

> Your pipeline can include library scanning - and scanning repositories for any open-source projects you use - **before** the build stage, so if there are any critical issues the build fails quickly and can be fixed.

## Infrastructure-as-Code Scanning

The final feature of Trivy is scanning infrastructure-as-code configuration files. It supports Terraform and CloudFormation configs, as well as Dockerfiles and Kubernetes YAML files.

📋 Scan the Dockerfile in `/labs/scanning/docker` and the Kubernetes manifest in `/labs/scanning/kubernetes`.

<details>
  <summary>Not sure how?</summary>

The `config` command looks for misconfigurations:

```
trivy config /labs/scanning/docker

trivy config /labs/scanning/kubernetes
```

</details>

You'll see a set of recommendations - these are best practices for your container images and deployment manifests.

## Lab

We've been running `trivy` commands inside a container. That works nicely with CI because you can install the Trivy command line in your build agent and use the same commands in your pipeline.

The downside is that developers won't use that workflow, so issues only get found when the build runs. Alternatively you can include scanning as a separate stage in a multi-stage Dockerfile:

- [hello-world-cs/Dockerfile](./hello-world-cs/Dockerfile) - builds .NET app with a stage to scan the application image; the Trivy command is set to look for HIGH severity issues, and return a non-zero exit code if there are any

Run the build and verify the Trivy test runs. Do you get an image? If there are failures, they could be with the OS tools - in which case you can fix them with a single change to the Dockerfile.

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
docker compose -f labs/scanning/docker-compose.yml down
```

> This removes only the containers this lab started. If you want
> a clean slate, `docker ps` will show anything still running.
