# Lab Solution

This is a workshop, so there is no single right answer. The model below shows
what the class results are expected to cover — if a row here is missing from
yours, there should be a reason for it.

## Part one: STRIDE for `app-01`

| Letter | Threat |
|---|---|
| **S** | Port 8080 is open to the whole internal network and app-01 does not verify that the request came from web-01. Any machine on the internal network can bypass the reverse proxy and send requests straight to the application — so all the filtering, rate limiting and TLS enforcement on web-01 can be skipped. |
| **S** | The application connects to the database with a single shared account. On the database side there is no "on behalf of which user" information; every operation appears as `siparis_app`. |
| **T** | `config.properties` is on disk and the application reads it. Someone who gets onto the server can change the database address and redirect traffic to their own server. |
| **R** | Application logs are on the local disk. And if transaction records carry no user identity, there is no answer to "who cancelled this order". |
| **I** | The password is plain text. And if debugging is on, stack traces can leak the database schema and the connection string. |
| **D** | A single instance. And if the connection pool is limited, requests sent directly to 8080 can exhaust it. |
| **E** | Which user does the application run as? If it is `root`, a remote code execution flaw in the application means the entire machine. |

**The real finding here:** the `web-01 → app-01` boundary is not actually a
boundary. It is drawn on the diagram but not enforced at the network level.
Without modelling you do not notice this, because the diagram looks right.

## Part two: three decisions

```
Threat    : Port 8080 being open to the whole internal network
Letter    : S (spoofing)
Impact    : Every control on the reverse proxy can be bypassed
Decision  : Eliminate
How       : Firewall rule - allow 8080 only from web-01's address
Owner     : Network team
Due date  : 2026-12-15
```

```
Threat    : The database password sitting in a plain-text file
Letter    : I (information disclosure)
Impact    : Anyone reaching app-01 can read all customer data
Decision  : Mitigate
How       : Password moves to a secret store, app fetches it at runtime
Owner     : Application team
Due date  : 2027-01-31
```

```
Threat    : Single application instance - service outage
Letter    : D (denial of service)
Impact    : Orders cannot be taken when app-01 is down
Decision  : Accept
Rationale : The business accepts a 4-hour recovery time, and at the current
            order volume the cost of an outage is below the cost of failover
            infrastructure. The container migration will run three replicas
            anyway; no separate investment will be made.
Owner     : Order product owner
Due date  : 2027-06-30 (revisit when the migration completes)
```

Note the third one: the moment its justification is written down, an "Accept"
decision becomes something that can be argued with. The sentence "4 hours is
acceptable" is approved by a business owner; it is not a decision the
technical team can make alone.

## Part three: the CI/CD pipeline

| Letter | Threat for the pipeline |
|---|---|
| **S** | Which identity does the pipeline use when it deploys to production? If it is a shared service account, there is no way to tell who triggered the deployment. |
| **T** | **The Jenkinsfile is in the repository.** Everyone who can write to that repository can change what the pipeline does — delete the scanning step, deploy their own image. If code review is not mandatory, one person is enough. |
| **T** | Dependencies pulled during the build. `npm install` or `pip install` downloads code from an external source and brings it into the build. |
| **R** | Is there a deployment record, and is it written by the pipeline itself? If whoever takes the pipeline can delete their own deployment from the record, there is no audit. |
| **I** | The pipeline's secrets: registry credentials, cluster access token, signing key. Are they printed into build logs? Can a pulled repository read them? |
| **D** | If the pipeline stops, it is not only new releases that stop — **urgent patches cannot ship either**. When a vulnerability is found, the route that would deploy the fix is closed. |
| **E** | How much cluster privilege does the pipeline have? If it was given `cluster-admin` when permission to deploy to one namespace would do, any flaw in the pipeline means the whole cluster. |

**The real finding here:** in the VM world, the thing that deployed to
production was *a person*, and that person's authority was defined in the
corporate directory. Now the thing that deploys is *software*, and in most
organisations its authority has never been reviewed. The permissions handed to
Jenkins at install time to "just make it work" are an open door to production
today.

That is why in this course the pipeline is the subject of the security
modules — treated not as an automation tool but as a **production system**.

___
> Back to the [exercises](README.md).
