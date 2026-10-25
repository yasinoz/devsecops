---
title: Threat Modelling Workshop
lang: en
slug: threat-modelling
section: security
order: 10
duration: 60
requires: []
status: updated
upstream: labs/threat-modelling
---
# Threat Modelling Workshop

Every security lab in this course **found** something: static analysis found a
pattern in the code, the scanner found a CVE, DAST found a missing header. All
of them were looking at something that already existed.

Threat modelling is unlike any of them, because it looks at something that
**does not exist yet**. No tool, no scan, no output file. There is a
whiteboard, a diagram of the system and a few people. Its output is not a
report but **decisions**.

Why is it worth it? Because every vulnerability you find has a cost, and that
cost compounds over time:

- caught in design → a one-sentence decision
- caught in code → one commit
- caught in test → a delayed release
- caught in production → a night, a disclosure, possibly a fine

Threat modelling is the top rung of that ladder. And it is the only activity
in this course that does not even need code to run.

> This is a workshop, not a command-line lab. There is nothing to run; you
> will read, discuss and write. It works best done as a group.

<!-- outcomes:auto -->
<!-- prereqs:auto -->
## Before you start

Takes about 60 minutes.

> Run every command from the **root of this repository** - the paths in this lab are written relative to it.

## Why this lab matters

Every other security activity in this course examines something that already exists. This one examines what has not been built yet, which is the only point where a flaw costs a sentence instead of a release. It also answers the question the whole course raises: moving to containers removes some threats, moves others, and creates new ones.

**After this lab you will be able to:**

- draw a system and mark where trust actually changes hands
- generate threats from a checklist instead of from imagination
- decide per threat: mitigate, eliminate, transfer or accept - in writing
- say which threats containers remove, which they move and which they add
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

## Reference

- [OWASP Threat Modeling Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html)

- [Microsoft — Threat modelling with STRIDE](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats)

- [NIST SSDF (SP 800-218) PW.1 — security requirements in design](https://csrc.nist.gov/pubs/sp/800/218/final)

- [OWASP ASVS — V1 Architecture, Design and Threat Modeling](https://owasp.org/www-project-application-security-verification-standard/)

## Four questions

Threat modelling looks complicated, but at its core it is four questions:

1. **What are we building?** — the diagram, the parts, the flows between them
2. **What can go wrong?** — the threats
3. **What are we going to do about it?** — a decision per threat
4. **Did we do a good job?** — reviewing the model itself

Most teams try to do the second and skip the first, and then fall apart. Do
not break the order.

## 1. What are we building

The system we are going to model is the enterprise version of the order
service you have seen in the labs throughout this course. We will work with
today's setup first — httpd, application server, SQL server.

```
  Internet
     │
     │  443/tcp
     ▼
┌─────────────────┐
│  web-01 (VM)    │   httpd 2.4, reverse proxy
│  DMZ network    │   TLS terminates here
└────────┬────────┘
         │  8080/tcp
         ▼
┌─────────────────┐
│  app-01 (VM)    │   application server
│  internal net   │   order business logic
└────────┬────────┘
         │  1433/tcp
         ▼
┌─────────────────┐
│  sql-01 (VM)    │   database
│  data network   │   order + customer data
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  SAN storage    │   LUN, nightly backup
└─────────────────┘
```

Details you need to know:

- httpd on `web-01` starts as `root`, then drops to the `apache` user
- `app-01` connects to the database as `siparis_app`; the password is in the
  application's `config.properties` in plain text
- `sql-01` is reachable only from the internal network — but from **all** of
  the internal network
- Backups are taken nightly as a LUN copy on the SAN, unencrypted
- Administrators connect directly to all three VMs over RDP/SSH
- Patching is done by hand in the monthly maintenance window
- Logs stay on each server's own disk for 30 days

> The same system moved onto containers is in part four of this lab; we will
> compare the two when we get there.

The one thing missing from the diagram is the **trust boundaries**: the places
where data crosses from one level of trust to another. Threats almost always
sit on those lines.

📋 How many trust boundaries does this system have? Where are they?

<details>
  <summary>Answer</summary>

At least four:

1. **Internet → web-01.** The obvious one. The other side is entirely
   untrusted.
2. **web-01 → app-01.** Between the DMZ and the internal network. If web-01
   is compromised, the attacker is standing on the inside of this boundary.
3. **app-01 → sql-01.** Between the application and the data. Whatever the
   application is allowed to do, so is the attacker.
4. **Administrator → all three VMs.** A separate boundary, because
   administrative access is a path entirely independent of the application's
   flow.

A fifth is arguable but important: **backup → SAN**. The data leaves the
system and enters a different management domain.

That last one gets skipped in most models. The production database is tightly
guarded while an unencrypted backup of the same data sits on storage managed
by another team.

</details><br/>

## 2. What can go wrong: STRIDE

Relying on imagination to produce threats does not work — everybody names the
attack they already know and the list goes no further. STRIDE gives you a
**checklist** instead. For each component you ask the same six questions in
order:

| Letter | Threat | Question |
|---|---|---|
| **S** | Spoofing | Can someone pretend to be someone else? |
| **T** | Tampering | Can they change the data or the code? |
| **R** | Repudiation | Can they deny what they did? |
| **I** | Information disclosure | Can they see what they should not? |
| **D** | Denial of service | Can they stop the system? |
| **E** | Elevation of privilege | Can they increase their privileges? |

### Let's do one together: `web-01`

| Letter | What it means in this system |
|---|---|
| **S** | If the TLS certificate is not validated, someone in the middle can act as web-01. Worse on the inside: app-01 does **not** verify that a request really came from web-01. Any machine on the internal network can connect straight to 8080. |
| **T** | The httpd configuration is on disk; anyone who gets onto the server can change the reverse-proxy rule and send traffic elsewhere. |
| **R** | Access logs are on the same server and kept 30 days. Whoever takes the server can erase their own trace. |
| **I** | `server_tokens` is on, so the version is advertised. More, if error pages show stack traces. |
| **D** | A single machine. If web-01 goes down the whole system is unreachable. |
| **E** | httpd starts as `root`. A flaw during startup means `root` directly. |

Those six rows took ten minutes, and finding none of them needed a tool.

📋 Now fill in the same table for `sql-01`. Pay attention to the details in
the system description — particularly where the password lives.

<details>
  <summary>Answer</summary>

| Letter | For `sql-01` |
|---|---|
| **S** | The `siparis_app` password is in plain text on `app-01`. Anyone who reaches app-01 can connect to the database as the application — and as far as the database is concerned that is a legitimate connection. |
| **T** | The same account has write permission; order records can be altered. If the application has `DDL` rights, so can the schema. |
| **R** | Is database auditing on? If not, there is no answer to "who changed this record". |
| **I** | Customer data lives here. The backups are **unencrypted** — the easiest way to take the data is not the live database but the nightly backup. |
| **D** | A single instance, no failover. And because any machine on the internal network can reach 1433, exhausting the connection pool is possible. |
| **E** | If the application account is `db_owner`, a SQL injection turns directly into database administrator rights. |

Note: most of these threats are not about `sql-01`'s own settings but about a
decision made on **another machine**. Threat modelling is done component by
component, but threats live between components.

</details><br/>

## 3. What are we going to do

There are four options for each threat. "Fix it" is only one of them:

- **Mitigate** — add the control. Move the password to a vault, restrict the
  account, encrypt the backups.
- **Eliminate** — remove the feature or the path. Close database access from
  the whole internal network and allow only app-01.
- **Transfer** — hand the risk to someone else. Do not hold payment data at
  all; leave it to the provider.
- **Accept** — live with it deliberately. **Written down**, with an owner and
  a date.

That last option is exactly the exception lines from the DAST and IaC labs.
What you wrote into a file there is decided here.

Use this shape for each row:

```
Threat    : Connecting to the database with the plain-text password on app-01
Letter    : S (spoofing)
Impact    : All customer data can be read
Decision  : Mitigate
How       : Password moves to a secret store, app fetches it at runtime
Owner     : Application team
Due date  : 2027-01-31
```

## 4. The same system in containers

Now the interesting part. You have moved the same system onto the stack you
built in this course:

```
  Internet
     │
     ▼
┌──────────────────────────────────────┐
│  Kubernetes cluster                  │
│                                      │
│  ┌────────┐   ┌────────┐   ┌──────┐  │
│  │ ingress│──▶│  app   │──▶│ sql  │  │
│  │        │   │(3 reps)│   │(stf) │  │
│  └────────┘   └────────┘   └──────┘  │
│       ▲            ▲                 │
│       │            │                 │
│  TLS here      image: registry       │
└──────────────────────────────────────┘
         ▲
         │  deployment
┌────────┴────────┐
│  CI/CD pipeline │  Jenkins, image build, scanning
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  image registry │
└─────────────────┘
```

- Images are built in the CI pipeline and pushed to the registry
- Deployment to the cluster is via GitOps; the manifest lives in a git
  repository
- The database password is in a Kubernetes `Secret`
- Cluster access is with `kubectl`, authenticated against the corporate
  directory
- Logs stream to a central collector
- Patching means rebuilding and redeploying the image

What happened to the threats?

📋 Sort them into three groups: which threats **disappeared**, which ones
**moved**, and which ones are **new**?

<details>
  <summary>Answer</summary>

**Disappeared:**

- httpd starting as `root` — the image runs as a specific user and Pod
  Security Standards enforce it
- "get onto the server and change the configuration" — the container's file
  system is read-only and comes from the image on restart; a change does not
  persist
- "patching is done by hand in the maintenance window" — patching means
  rebuilding the image, so it goes through the pipeline

**Moved:**

- *Password in a plain-text file* → into a Kubernetes `Secret`. Better, but a
  `Secret` is base64 by default — not encrypted. The threat did not
  disappear; it moved to **etcd** and to **RBAC**.
- *Everyone on the internal network can reach SQL* → a question of in-cluster
  network policy. If no policy is written the situation is **the same**, or
  wider.
- *Administrators SSH into the VMs* → `kubectl exec`. Same privilege,
  different door; and whether that door is logged is a separate question.

**New:**

- **The registry.** That is where the image comes from. If the registry is
  compromised or an image tag is moved, the attacker's code is deployed to the
  cluster. There was no equivalent of this in the VM world.
- **The CI/CD pipeline.** The pipeline can write to production. Whoever takes
  the pipeline takes production. Jenkins is no longer a helper tool; it is a
  **production system**.
- **The GitOps repository.** The deployment manifest is in git; whoever can
  write to that repository can deploy to the cluster.
- **The supply chain.** The image contains hundreds of packages. So did the
  VM, but the image is rebuilt constantly, so something new can enter on every
  build.
- **The cluster API.** A misconfigured RBAC role can grant access to the whole
  cluster instead of a single namespace.

</details><br/>

### What follows from this

Moving to containers does not automatically improve security. It genuinely
eliminates some classes of threat — mostly the ones about *maintaining
machines*. In exchange it opens a **new and unfamiliar** surface: where the
image came from, who owns the pipeline, who the cluster grants what.

It also explains why the modules in this course are ordered the way they are:
image building, registries, scanning, golden images, GitOps, policy
enforcement — every one of them is an answer to something on that "new" list.

## Lab

Complete the model.

**Part one — the current system.** Fill in the STRIDE table for `app-01`. Use
the `web-01` and `sql-01` tables above as examples. Write at least six
threats; do not force a row for every letter — some letters may be empty for a
component, but leave them empty knowingly.

**Part two — decisions.** Pick **three** of the threats you produced and fill
in the decision shape: impact, decision, how, owner, due date. Make at least
one of the three an "Accept" — so that you have to write the justification.

**Part three — the new architecture.** In the containerised setup, model the
**CI/CD pipeline**. The pipeline is a component; apply STRIDE to it. A hint:
the pipeline has permission to write to production, and it takes its code from
a git repository.

Share the result with the class. The real output of this workshop is not the
table but the discussion — two people looking at the same system see different
threats, and that is where the value is.

> Stuck? Take a look at the [hints](hints.md) or the
> [solution](solution.md).
___

<!-- troubleshooting:auto -->


## Cleanup

Nothing was run in this workshop, so there is nothing to clean up.

Keep the model you produced. A threat model is not a one-off document: it gets
reopened when the architecture changes, and the question "which threat does
this change affect" gets asked again.
