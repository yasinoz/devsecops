---
title: Enforcing Workload Policies
lang: en
slug: admission
section: security
order: 5
duration: 60
requires: [docker, kubernetes]
status: needs-review
upstream: labs/admission
---
# Controlling Admission

Admission control is the process of allowing - or blocking - workloads from running in the cluster. You can use this to enforce your own rules. You might want to block all containers unless they're using an image from an approved registry, or block Pods which don't include resource limits in the spec.

You can do this with admission controller webhooks - HTTP servers which run inside the cluster and get invoked by the API to apply rules when objects are created. Admission controllers can use your own logic, or can use a standard tool like [Open Policy Agent](https://www.openpolicyagent.org).

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

- [Using admission controllers](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/docs/)
- [Gatekeeper policy library](https://github.com/open-policy-agent/gatekeeper-library)


## Validating and Mutating Webhooks

You can write your own admission control logic in a REST API which you run in the cluster, and configure rules which apply to Kubernetes objects:

- [this ValidatingWebhookConfiguration](./specs/validating-webhook/validatingWebhookConfiguration.yaml) fires when Pods are created or updated in the cluster, and calls the validate method on a custom webhook server; the server will return whether the action is allowed to proceed

- [this MutatingWebhookConfiguration](./specs/mutating-webhook/mutatingWebhookConfiguration.yaml) - fires when Pods are created or updated, and calls the mutate endpoint on the server; this could edit the spec and send back the changes before Kubernetes runs the action.

We could run a webhook server in the cluster - these examples work with a demo NodeJS web app ([source code on GitHub](https://github.com/sixeyed/kiamol/tree/master/ch16/docker-images/admission-webhook/src)) - but there's a more common alternative.

## Run OPA Gatekeeper

Custom webhooks have two drawbacks: you need to write the code yourself, which adds to your maintenance estate; and their rules are not discoverable through the cluster, so you'll need external documentation.

OPA Gatekeeper is an alternative which implements admission control using generic rule descriptions (in a language called [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/)).

We'll deploy admission rules with Gatekeeper - which is another CNCF project. It extends Kubernetes with new object types, and you use those objects to store and apply your own rules.

OPA Gatekeeper is another complex component, where you trade the overhead of managing it with the issues of running your own controllers:

- [opa-gatekeeper/v3.23.1.yaml](./specs/opa-gatekeeper/v3.23.1.yaml) - deploys custom resources to describe admission rules, RBAC for the controller and a Service and Deployment to run it

_Deploy OPA:_

```
kubectl apply -f labs/admission/specs/opa-gatekeeper
```

📋 What custom resource types does Gatekeeper install?

<details>
  <summary>Not sure?</summary>

Check the CustomResourceDefinitions:

```
kubectl get crd
```

You'll see a few - the main one we work with is the ConstraintTemplate.

</details><br/>

## Deploy OPA admission rules

There are two parts to applying rules with Gatekeeper:

1. Create a _ConstraintTemplate_ which defines a generic constraint (e.g. containers in a certain namespace can only use a certain image registry)

2. Create a _Constraint_ from the template (e.g. containers in namespace `whoami` can only use images from `courselabs` repos on Docker Hub)

The rule definition is done with the Rego generic policy language:

- [requiredLabels-template.yaml](./specs/opa-gatekeeper/templates/requiredLabels-template.yaml) - defines a simple (!) template to require labels on an object

- [resourceLimits-template.yaml](./specs/opa-gatekeeper/templates/resourceLimits-template.yaml) - defines a more complex template requiring container objects to have resources set

Create the templates:

```
kubectl apply -f labs/admission/specs/opa-gatekeeper/templates
```

📋 Check the custom resources again; how do you think Gatekeeper stores constraints in Kubernetes?

<details>
  <summary>Not sure?</summary>

```  
kubectl get crd
```

You see new CRDs for the constraint templates:

```
policyresourcelimits.constraints.gatekeeper.sh

requiredlabels.constraints.gatekeeper.sh
```

Gatekeeper creates a CRD for each constraint template, so each constraint becomes a Kubernetes resource.

</details><br/>

Here are the constraints which use the templates:

- [requiredLabels.yaml](./specs/opa-gatekeeper/constraints/requiredLabels.yaml) - requires `app` and `version` labels on Pods, and a `kubernetes.courselabs.co` label on namespaces

- [resourceLimits.yaml](./specs/opa-gatekeeper/constraints/resourceLimits.yaml) - requires resources to be specified for any Pods in the `apod` namespace

Deploy the constraints:

```
kubectl apply -f labs/admission/specs/opa-gatekeeper/constraints
```

📋 Print the details of the required labels namespace constraint. Is it clear what it's enforcing?

<details>
  <summary>Not sure?</summary>

The constraint type is a CRD so you can list objects in the usual way:

```  
kubectl get requiredlabels

kubectl describe requiredlabels requiredlabels-ns
```

You'll see all the existing violations of the rule, and it should be clear what's required - the label on each namespace.

</details><br/>

Rego is not a straightforward language - but it is a generic way of defining policies. Trivy uses Rego for its [misconfiguration check library](https://github.com/aquasecurity/trivy-checks) (which used to live in a repo called appshield).

## Verify the OPA rules

This application YAML in the `labs/admission/specs/pi` folder violates all the OPA rules for namespaces and Pods.

📋 Deploy the app. Does it run?

<details>
  <summary>Not sure?</summary>

Use Kubectl apply:

```
kubectl apply -f labs/admission/specs/pi
```

You'll see errors saying that the namespace can't be created because of a policy violation, and then the other objects can't be created because the namespace doesn't exist.

</details>

Some policy failures happen on the objects which you create with Kubectl - so you see clear validation errors like this.

The fix is in [fix-1/01-namespace.yaml](./specs/pi/fix-1/01-namespace.yaml) which adds the required label to the namespace. Deploy the fixed version and check the output:

```
kubectl apply -f labs/admission/specs/pi/fix-1
```

The output from Kubectl says all the objects are created. It should be listening at http://localhost:30031. Is it working? No... The Service has been created but there's no response from it.

📋 Can you debug to see what the problem is?

<details>
  <summary>Not sure how?</summary>

Start by describing the Service:

```
kubectl describe svc pi-np -n pi
```

You'll see there are no _Endpoints_ which means no Pods are enlisted as targets for the Service to route traffic.

Try listing all the Pods in the namespace:

```
kubectl get po -n pi
```

None. Hmm. How about Deployments and ReplicaSets?

```
kubectl get deploy,rs -n pi
```

They've been created but there are no Pods. Describe the ReplicaSet to see the problem:

```
kubectl describe rs -n pi
```

Now you'll see the error.

</details>

The OPA Gatekeeper policy blocks Pods from being created - there are two warning messages in the events which tell you why:

```
Error creating: admission webhook "validation.gatekeeper.sh" denied the request: [resource-limits] container <pi-web> has no resource limits

Error creating: admission webhook "validation.gatekeeper.sh" denied the request: [requiredlabels-pods] you must provide labels: {"version"}
```

But you don't see that in Kubectl, because you're not creating Pods directly - you create a Deployment, which creates a ReplicaSet which creates the Pods.

The Pod template in [fix-2/deployment.yaml](./specs/pi/fix-2/deployment.yaml) adds the necessary labels and resources.

📋 Deploy the fix-2 YAML - does the app work now?

<details>
  <summary>Not sure how?</summary>

```
kubectl apply -f labs/admission/specs/pi/fix-2

kubectl get pods -n pi
```

Looking good :)

</details>

Try the app now at http://localhost:30031. It's running with a constrained amount of CPU and memory, and from an ops perspective it's easy to manage because it has a consistent set of labels.

## Lab

Your turn to try deploying an app and making sure it meets the admission requirements.

Try deploying the demo Astronomy Picture of the Day app from the specs for this lab:

```
kubectl apply -f labs/admission/specs/apod
```

It will fail because the resources don't meet the constraints we have in place. Your job is to fix up the specs and get the app running - without making any changes to policies :)

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

Remove all the lab's namespaces, which removes all the other objects:

```
kubectl delete ns -l kubernetes.courselabs.co=admission
```

Except the CRDs:

```
kubectl delete crd -l gatekeeper.sh/system

kubectl delete crd -l gatekeeper.sh/constraint
```

And - **this one matters** - the webhook configurations:

```
kubectl delete validatingwebhookconfiguration servicetokenpolicy gatekeeper-validating-webhook-configuration cert-manager-webhook --ignore-not-found

kubectl delete mutatingwebhookconfiguration nonrootpolicy gatekeeper-mutating-webhook-configuration cert-manager-webhook --ignore-not-found
```

> Webhook configurations are **cluster-scoped** - deleting the namespaces does
> not remove them. If you leave them behind, the API server keeps calling a
> webhook service that no longer exists, and **every later lab fails** with
> errors like *"failed calling webhook ... service not found"* - you will not
> even be able to create a namespace. If you hit that, run the two commands
> above to recover.

