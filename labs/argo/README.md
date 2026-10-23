---
title: GitOps with ArgoCD
lang: en
slug: argo
section: security
order: 4
duration: 60
requires: [docker, kubernetes]
status: updated
upstream: labs/argo
---
# GitOps with ArgoCD

GitOps turns the CI/CD approach on its head - instead of an external automation server pushing changes into the cluster, a tool inside the cluster monitors a Git repo and pulls in any changes.

It means your cluster can be secured more cleanly, because you don't need a cluster admin user for the automation server. It also means your app definitions - and even the infrastructure setup for cloud services - can be definitively stored in Git repos. You can recreate your whole deployment from scratch.

<!-- outcomes:auto -->
## Why this lab matters

Giving a build server cluster-admin credentials is how CI pipelines become the softest target in your infrastructure. GitOps inverts it: an agent inside the cluster pulls from Git, so nothing outside needs write access - and the repository becomes the record of what is actually deployed.

**After this lab you will be able to:**

- install ArgoCD into a cluster
- point an application at a Git repository and let ArgoCD deploy it
- watch a change in Git reach the cluster without anyone running `kubectl apply`
- explain why pull-based delivery is easier to secure than push-based
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

Takes about 60 minutes.

**Docker Desktop** must be running. Check it:

```
docker version
```

A `Server:` section in the output means you are ready. If you get an error
instead, start Docker Desktop and wait until the whale icon stops animating.

A **Kubernetes cluster** must be running. Docker Desktop ships one:
*Settings -> Kubernetes -> Enable Kubernetes*. Check it:

```
kubectl get nodes
```

You should see at least one node with `STATUS` of `Ready`. If the command
hangs or errors, the cluster is still starting - give it a minute and try
again.

> Run every command from the **root of this repository** - the paths in this lab are written relative to it.

## Reference

- [GitOps](https://www.gitops.tech) - describing the approach and its adoption

- [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) - the GitOps project in the CNCF

- [ArgoCD command line](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd/)

- [Application CRD spec](https://argo-cd.readthedocs.io/en/stable/operator-manual/application.yaml)

- [GitOps with Kubernetes and Argo](https://eltons.show/episodes/ecs-c3/) - my YouTube walkthrough

## Install ArgoCD

ArgoCD has a server-side component which runs in the cluster and watches the configured Git repos for your projects. There's also a command line tool which you can use to set up and manage projects.

Start by installing the CLI - use the [full install docs](https://argo-cd.readthedocs.io/en/stable/cli_installation/) or one of these quick options:

```
# Windows:
choco install argocd-cli

# Mac:
brew install argocd

# Linux:
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
```

Check your installation with:

```
argocd version
```

> You'll see the client version and then a server error - the CLI can't connect to the ArgoCD server, because we haven't deployed it yet.

There's a local copy of the Argo CD spec here:

- [argocd/v3.5.5.yaml](./specs/argocd/v3.5.5.yaml) - it installs a lot of resources, including CustomResourceDefinitions - CRDs - which extend the functionality of Kubernetes. ArgoCD adds an `Application` resource to the cluster.

Deploy the server components:

```
kubectl apply --server-side -n argocd -f labs/argo/specs/argocd
```
> `--server-side` is needed here. A plain `kubectl apply` records the whole
> manifest in an annotation, and ArgoCD's `applicationsets` CRD is larger than
> the 262KB limit Kubernetes allows for annotations - the install fails with
> *"metadata.annotations: Too long"*. Server-side apply does not write that
> annotation.


Argo installs a new custom object type called _Application_.

📋 List all of the application objects in the cluster.

<details>
  <summary>Not sure how?</summary>

Custom objects can be used in Kubectl like ordinary objects:

```
kubectl get applications
```

</details><br/>

This installation of ArgoCD includes a web UI. The initial admin password is stored in a Secret - run this to view the password in plain text:

```
kubectl -n argocd get secret argocd-initial-admin-secret -o go-template="{{.data.password | base64decode}}"
```

Open the UI at http://localhost:30881, log in with username `admin` and the password from your Secret.

> You'll be redirected to HTTPS with a self-signed certificate, so you'll need to accept the security warning in your browser.

Open https://localhost:30881/settings/clusters - ArgoCD is registered with the local cluster so it can manage applications, but there are no apps yet.

## Configure the Git server

ArgoCD deploys apps as units which are configured with a source code repo to watch. The contents of the repo can be standard Kubernetes YAML, Helm charts or Kustomize. 

ArgoCD monitors the repo, and whenever there is a change - so the running app is out of sync with the specifications in the source repo - it fetches the changes and updates the app.

We'll run a local Git server to make the deployment simple:

- [gitea/gitea.yaml](./specs/gitea/gitea.yaml) is the same Gitea server we used in the Jenkins lab, configured to run in Kubernetes

Deploy the Git server:

```
kubectl apply -f labs/argo/specs/gitea
```

Browse to http://localhost:30300/ and when the site is ready, sign in with username `student` and password `student`.

Add the new Git server as a remote for this repo and push a copy of the content:

```
# add the local Git server:
git remote add labs-argo http://localhost:30300/student/labs.git

git push labs-argo main
```

> Older versions of this lab pushed `main:master`, because the ArgoCD version
> of the day defaulted to a `master` branch. ArgoCD tracks `HEAD` by default
> now - the Git server's own default branch - so pushing `main` is enough and
> there's no need for a second branch name.

Now connect the ArgoCD CLI to the ArgoCD server, **using your password from the Secret**:

```
argocd login localhost:30881 --insecure --username admin --password <your-password>

argocd cluster list
```

> You can add new clusters to deploy to a remote Kubernetes cluster. Apps can be managed with the CLI or with the UI.

## Deploy an application

Create an application for the app in the `labs/argo/project/whoami` folder - that folder contains a simple whoami app spec:

```
argocd app create whoami --repo http://gitea.infra.svc.cluster.local:3000/student/labs.git --path labs/argo/project/whoami --dest-server https://kubernetes.default.svc --dest-namespace default --sync-policy auto --self-heal
```

> Creating the app stores the definition in Kubernetes, and we've set the sync policy to _auto_ - so it will be deployed straight away.

You can also create apps by deploying Kubernetes YAML. Here's the same application as an [Application object](./specs/apps/whoami.yaml) - it uses `targetRevision: HEAD` so it follows whatever the Git server's default branch is called.

📋 Check the details of the new application with the Argo CLI.

<details>
  <summary>Not sure how?</summary>

Applications are just Kubernetes objects - you can query them with Kubectl. But you get the key information in a readable format from the Argo CLI:

```
argocd app list

argocd app get whoami
```

</details><br/>


You can also see the new application in the UI at https://localhost:30881/applications. You'll see the status is _Synced_ and if you open the app you'll see all the Kubernetes resources.

ArgoCD deploys the app from the YAML specs in the repo - with no pipeline or scripts to maintain. You can test the app at http://localhost:30010/.


## Lab

Now let's see GitOps in action, making a change to the Docker image tag for the app, so it triggers a rollout with new Pods.

Edit the Kubernetes [deployment.yaml](./project/whoami/deployment.yaml) file and make two changes:

- set the image tag to `ghcr.io/yasinoz/courselabs/whoami-lab:21.09-4`
- set the replica count to 3

Trigger the update by pushing your changes to the local Git server.

This ArgoCD application is set to self-heal, which means if an administrator removes any resources, ArgoCD will recreate them. Confirm that by deleting the Kubernetes Deployment object.


> Stuck? Try [hints](hints.md) or check the [solution](solution.md).

___

<!-- troubleshooting:auto -->
## If something goes wrong

**`The connection to the server ... was refused`** - the cluster is not
running. Enable Kubernetes in Docker Desktop and wait for it to start.

**`provided port is already allocated`** - a Service from an earlier lab still
holds that NodePort. Find it with `kubectl get svc -A` and delete the namespace
that lab created.

**`failed calling webhook ... service not found`** - leftovers from the
**admission** lab are blocking the API server, and you will not be able to
create anything, not even a namespace. That lab's Cleanup section has the two
commands that remove the webhook configurations.

**Pod stuck in `ContainerCreating` or `Pending`** - usually the image is still
downloading, which can take a few minutes the first time. Check with
`kubectl describe pod <name>` and read the **Events** at the bottom: they say
exactly what the Pod is waiting for.

**Pod in `CrashLoopBackOff`** - the container starts and exits. The reason is
in its logs: `kubectl logs <name>`. Add `--previous` to see the run before the
last restart.

Still stuck? The **Cleanup** section below resets everything, so you can start
the lab again from a clean cluster.


## Cleanup

Deleting apps in ArgoCD doesn't remove the running application - unless you use the cascade flag:

```
argocd app delete whoami --cascade
```

> ArgoCD asks you to confirm you really want to do this :)

Then delete the lab namespaces, which will remove ArgoCD and Gitea:

```
kubectl delete ns -l kubernetes.courselabs.co=argo
```

And remove the Git remote:

```
git remote rm labs-argo
```

Deleting the namespaces does **not** remove ArgoCD's custom resource
definitions - they are cluster-wide objects that live outside any namespace.
They are harmless on their own, but they make `kubectl get crd` confusing in
later labs, so clear them too:

```
kubectl delete crd applications.argoproj.io applicationsets.argoproj.io appprojects.argoproj.io --ignore-not-found
```
