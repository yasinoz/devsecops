---
title: Environment Setup
lang: en
slug: setup
section: index
order: 0
status: updated
upstream: setup/README.md
---
# Environment Setup

The labs use a lot of tools — Jenkins, Prometheus, Elasticsearch, Trivy and
more. You won't install any of them. Everything runs in containers, so you
need exactly two things on your machine: **Docker** and **Git**.

> You don't need Docker experience for this course. Every command is given to you.

## 1. Git

Git is free and open source:

- [Install Git](https://git-scm.com/downloads) (Windows, macOS, Linux)

On Windows this also gives you **Git Bash**. Use **PowerShell** for these
labs anyway.

> **Why not Git Bash?** It rewrites any argument that looks like a Linux path.
> A command like `kubectl exec deploy/pi-web -- cat /var/run/secrets/...`
> becomes `C:/Program Files/Git/var/run/secrets/...` and fails with
> `No such file or directory` - while the file is sitting there inside the
> container. You would be debugging your shell instead of the lab. If you
> really prefer Git Bash, put `MSYS_NO_PATHCONV=1` in front of those
> commands.

## 2. Docker

### Windows and macOS — Docker Desktop

- [Install Docker Desktop](https://www.docker.com/products/docker-desktop)

The install takes a few minutes and may want a restart on Windows. When it's
done, start **Docker Desktop** and wait for the whale icon in the taskbar
(Windows) or menu bar (macOS) to stop animating.

> **Licensing note.** Docker Desktop is free for personal use, education and
> small businesses, but larger organisations need a paid subscription. If your
> employer's rules rule it out, use [Rancher Desktop](https://rancherdesktop.io)
> or [Podman Desktop](https://podman-desktop.io) — the `docker` commands in
> these labs work with both.

### Linux — Docker Engine

<details>
  <summary>Running Docker on Linux</summary>

If you're using WSL on Windows, install Docker Desktop instead — it integrates
with your WSL distro and is much less work.

- [Install Docker Engine](https://docs.docker.com/engine/install/) (includes
  the Compose plugin)

Then make sure the service is running and add yourself to the `docker` group so
you don't need `sudo` for every command:

```
sudo systemctl start docker

sudo usermod -aG docker $USER

newgrp docker
```

To start Docker automatically on boot:

```
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
```

> Being in the `docker` group is equivalent to root access on the host. That's
> fine on your own lab machine; it is a deliberate decision on a shared one.

</details><br />

## 3. Check your setup

Three commands. You need output from all three.

```
git --version
```

```
docker version
```

Make sure you see **two** sections, `Client:` and `Server:`. Client only means
the Docker engine isn't running — start Docker Desktop and wait.

```
docker compose version
```

> ⚠️ Note the **space**: `docker compose`, not `docker-compose`. The old
> `docker-compose` (v1) command reached end of life in June 2023 and is no
> longer shipped. Every lab here uses the v2 syntax. If you find a
> `docker-compose` call anywhere in these labs, that's a bug — please report it.

Version numbers don't need to match anyone else's. If a command errors, fix it
now — nothing in this course works without a running Docker engine.

<details>
  <summary>Permission denied on Linux?</summary>

Add your user to the `docker` group and start a new session:

```
sudo usermod -aG docker $USER

# log out and back in, or:
su $USER
```

</details><br />

<details>
  <summary>Windows: "no matching manifest for windows/amd64"?</summary>

Docker Desktop is in *Windows container* mode. Right-click the whale icon and
choose **Switch to Linux containers**. Linux mode is the default and is what
these labs need.

</details><br />

## 4. Sign in to Docker Hub

Create a [free Docker Hub account](https://hub.docker.com/signup) and log in:

```
docker login
```

This isn't bureaucracy. Docker Hub limits anonymous image pulls **per IP
address**. In a classroom everyone shares one public IP, so the limit gets used
up by the third student and the rest see:

```
toomanyrequests: You have reached your pull rate limit
```

Authenticated accounts get a much higher allowance, counted per user instead of
per IP. One `docker login` saves the whole room.

## 5. Kubernetes (only for the last three labs)

The GitOps, admission control and container security labs need a cluster. Any
single-node cluster works. Pick one:

### Docker Desktop (easiest)

**Settings → Kubernetes → Enable Kubernetes → Apply & Restart.** Takes a few
minutes on first run.

### k3d, kind or minikube

<details>
  <summary>Alternatives if you're not using Docker Desktop</summary>

All three run a cluster inside Docker containers:

```
# k3d
k3d cluster create labs --port "30000-30100:30000-30100@server:0"

# kind
kind create cluster --name labs

# minikube
minikube start
```

> The labs reach services through **NodePorts** in the 30000+ range. With k3d
> you need the port mapping shown above; with kind you need an
> `extraPortMappings` config; with minikube use `minikube service` or
> `minikube tunnel`.

</details><br />

Check it:

```
kubectl version

kubectl get nodes
```

You need `Ready` for at least one node, and a `kubectl` client of **1.30 or
newer**.

## 6. Give Docker enough memory

Elasticsearch, Kibana and SonarQube are heavy. On Docker Desktop:

**Settings → Resources** → set memory to at least **6 GB** (8 GB is
comfortable).

If a container dies on its own with exit code 137, it ran out of memory — that
is the symptom to remember.

## 7. Get the labs

```
git clone https://github.com/yasinoz/devsecops.git

cd devsecops
```

Run every lab command from this folder, not from inside the lab directory.
Paths in the labs are written relative to the repo root:

```
docker compose -f labs/jenkins/infra/docker-compose.yml up -d
```

> **Windows line endings.** This repo pins line endings to LF via
> `.gitattributes`, which matters: a shell script checked out with CRLF fails
> inside a Linux container with `bad interpreter`. If you cloned before that
> file existed, re-clone.

## Optional but useful

- [Visual Studio Code](https://code.visualstudio.com) — browse the repo, read
  the Dockerfiles, edit YAML with validation
- [Windows Terminal](https://aka.ms/terminal) — tabs, which you'll want
- `kubectl` [autocompletion](https://kubernetes.io/docs/tasks/tools/included/optional-kubectl-configs-bash-linux/)

## You're ready

Back to the [lab index](../index.md).
