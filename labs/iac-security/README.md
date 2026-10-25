---
title: Infrastructure as Code Security
lang: en
slug: iac-security
section: security
order: 4
duration: 45
requires: [docker]
status: updated
upstream: labs/iac-security
---
# Infrastructure as Code Security

We no longer build the server, the storage bucket and the security group by
clicking through a console; we write them in a file and apply it. This is
**IaC** (Infrastructure as Code), and what it buys is repeatability: the same
file builds the same infrastructure.

But repeatability cuts both ways. A wrong setting made in a console affects
one server; **a wrong setting sitting in code is reproduced every time that
code is applied.** Three environments, ten accounts, autoscaling — all of them
carry the same mistake. And the mistake stays, because nobody fixes anything
by hand any more.

The good news: because infrastructure is now a text file, it can be **read
before it is built**. The Terraform code in this lab will never be applied
anywhere. There is no AWS account, no credentials, no `terraform apply`. The
scanner will read the file and tell you that the bucket about to be created
would be public — before the bucket exists.

Our tool is [Trivy](https://trivy.dev/) again. In image scanning it looked at
packages; with the `config` command it looks for misconfigurations in
Terraform, CloudFormation, Kubernetes and Dockerfile files.

<!-- outcomes:auto -->
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

## Why this lab matters

A wrong click in a console affects one server; a wrong line in infrastructure code is rebuilt every time that code is applied, in every environment. The compensation is that infrastructure is now a text file, so it can be read before anything is created - the bucket that would have been public never exists.

**After this lab you will be able to:**

- scan Terraform for misconfigurations without applying it anywhere
- separate the tool's severity from your own priority
- see how fixing one rule creates new infrastructure that needs the same rules
- write an exception that expires by itself instead of being forgotten
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

- [Trivy — Misconfiguration scanning](https://trivy.dev/latest/docs/scanner/misconfiguration/)

- [AWS Vulnerability Database — check list](https://avd.aquasec.com/misconfig/)

- [OWASP Top 10 — A05:2021 Security Misconfiguration](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/)

- [NIST SSDF (SP 800-218) PW.9 — secure default configuration](https://csrc.nist.gov/pubs/sp/800/218/final)

## Reading the infrastructure

Open `labs/iac-security/altyapi/main.tf` in your editor. It is not long: an S3
bucket, the bucket's public-access settings, and a security group.

As you read it, look for this: **can you see a deliberately planted
vulnerability?**

You cannot, because there is none. This file is what a Terraform file
ordinarily looks like. It defines the bucket, opens the group, and works.
Everything left unsaid falls back to the provider's default — and in the cloud
defaults are not secure, they are *easy*.

## The first scan

```
docker run --rm -v ./labs/iac-security:/is aquasec/trivy:0.76.0 config /is/altyapi -q
```

> On the first run Trivy downloads its checks bundle from the internet, which
> takes a few seconds. Later runs read it from cache. In an environment with
> no internet access this step fails.

```
Failures: 12 (UNKNOWN: 0, LOW: 4, MEDIUM: 1, HIGH: 6, CRITICAL: 1)
```

Twelve findings:

```
AWS-0086 (HIGH):     Public access block does not block public ACLs
AWS-0087 (HIGH):     Public access block does not block public policies
AWS-0089 (LOW):      Bucket has logging disabled
AWS-0090 (MEDIUM):   Bucket does not have versioning enabled
AWS-0091 (HIGH):     Public access block does not ignore public ACLs
AWS-0093 (HIGH):     Public access block does not restrict public buckets
AWS-0099 (LOW):      Security group explicitly uses the default description.
AWS-0104 (CRITICAL): Security group rule allows unrestricted egress to any IP address.
AWS-0107 (HIGH):     Security group rule allows unrestricted ingress from any IP address.
AWS-0124 (LOW):      Security group rule does not have a description.
AWS-0124 (LOW):      Security group rule does not have a description.
AWS-0132 (HIGH):     Bucket does not encrypt data with a customer managed key.
```

Under each finding the output shows the file name, the line number and the
relevant piece of code. There is also a link like
`https://avd.aquasec.com/misconfig/aws-0086` — open it, and you will find why
the rule exists.

### What just happened

**Nothing was created** in that scan. Terraform did not run, no API call was
made, no account was contacted. Trivy read the HCL file and said "the resource
this code would create does not meet these rules".

There is also a way to find the same finding in running infrastructure — cloud
security posture tools do that. But by then the bucket has been created, has
perhaps taken data, has perhaps been open to the internet. The difference here
is not hours; it is that **the resource never existed**.

## Severity is not priority

📋 The only `CRITICAL` in the list is `AWS-0104` — unrestricted egress. Would
you fix that one first?

<details>
  <summary>Answer</summary>

Probably not.

`AWS-0104` is **unrestricted egress**: the server can connect to any address
on the internet. It is a real risk — it is the easiest route for data
exfiltration. But in most architectures it is left open deliberately: package
downloads, external API calls, updates. Closing it requires proxy
infrastructure.

`AWS-0107` is only `HIGH`, but **the SSH port is open to the whole
internet**. That is the door somebody who scanned you last night starts
guessing passwords on today. The fix is one line: the company network's range
instead of `0.0.0.0/0`.

The four `HIGH` public-access findings (`0086`, `0087`, `0091`, `0093`) should
also be read together: they are four settings on one resource, and if even one
stays `false` the bucket can be made public by accident. One fix, four
findings.

**Severity is the score the tool gives; priority is your decision.** The
tool's ranking does not know your architecture, how sensitive your data is, or
what that resource is connected to.

</details><br/>

## Applying the fix

The file `labs/iac-security/altyapi-duzeltilmis/main.tf` describes the same
infrastructure in a fixed form. Open it and read: each block is annotated with
the finding it closes — a KMS key for encryption, versioning, access logging,
the four public-access settings, a narrowed range for SSH, descriptions.

Scan that folder:

```
docker run --rm -v ./labs/iac-security:/is aquasec/trivy:0.76.0 config /is/altyapi-duzeltilmis -q
```

```
Failures: 9 (UNKNOWN: 0, LOW: 2, MEDIUM: 1, HIGH: 5, CRITICAL: 1)
```

Down from 12 to 9. And yet **all twelve fixes** are in that file.

📋 Look carefully at the remaining 9. What are they about?

<details>
  <summary>Answer</summary>

```
AWS-0086 (HIGH):     No public access block so not blocking public acls
AWS-0087 (HIGH):     No public access block so not blocking public policies
AWS-0089 (LOW):      Bucket has logging disabled
AWS-0090 (MEDIUM):   Bucket does not have versioning enabled
AWS-0091 (HIGH):     No public access block so not blocking public acls
AWS-0093 (HIGH):     No public access block so not restricting public buckets
AWS-0094 (LOW):      Bucket does not have a corresponding public access block.
AWS-0104 (CRITICAL): Security group rule allows unrestricted egress to any IP address.
AWS-0132 (HIGH):     Bucket does not encrypt data with a customer managed key.
```

Eight of them are about a **new bucket**: `arsiv_kayitlari`.

`AWS-0089` said "logging is disabled". To fix it we had to create a bucket for
the logs to be written to. That bucket is an S3 bucket too — so it has no
encryption, no versioning, no public-access block and no access logging of its
own.

The messages in the first scan said "`Public access block does not
block...`"; now they say "**No** public access block so not blocking...". In
the first case the block existed but was `false`; in the second there is no
block at all.

The ninth is `AWS-0104`: we narrowed egress to 443, but the destination is
still `0.0.0.0/0`. The port was restricted, the address was not — the rule
says "any IP address", and it is right.

</details><br/>

### The lesson here

In infrastructure code, **a fix gives birth to new infrastructure.** The
resource you add to satisfy one rule is itself subject to the same rules. A
log bucket, a backup bucket, a KMS key, a proxy — every one of them is new
surface.

This is why IaC scanning cannot be a one-off cleanup; it has to be **a check
that runs on every change**. "We fixed it, we are done" does not hold here:
you are opening something new at the very moment you fix something.

## The gate

Let's make it stop the pipeline. Trivy needs `--exit-code` to return a
non-zero code when there are findings, and `--severity` decides what counts.

```
docker run --rm -v ./labs/iac-security:/is aquasec/trivy:0.76.0 config /is/altyapi -q --severity HIGH,CRITICAL --exit-code 1
```

Check the exit code — `echo $LASTEXITCODE` in Windows PowerShell, `echo $?` on
macOS or Linux. You will see **1**.

Why `HIGH,CRITICAL`? Because there are four `LOW` findings in this list and
three of them say "no description written". They are correct warnings, but
they are not worth stopping a release for. Put them all in the gate and the
team will switch the gate off within a week.

> The gate's threshold is the intersection of what is expected to be fixed and
> what is worth stopping the pipeline for. `LOW` findings go into the report,
> accumulate, and get cleaned up when their turn comes — but they do not hold
> up a release.

## Exceptions: a decision with a date

`AWS-0104` is still in the fixed file, and it is `CRITICAL`. Closing egress
needs proxy infrastructure, and that is not happening this quarter. So we are
going to accept it for a while.

Open `labs/iac-security/istisna.yaml` and look. It has three fields, and all
three are treated as required: which finding, **why** it was accepted, and
**when** it will be looked at again.

Scan without the exception:

```
docker run --rm -v ./labs/iac-security:/is aquasec/trivy:0.76.0 config /is/altyapi-duzeltilmis -q --severity CRITICAL
```

```
Failures: 1 (CRITICAL: 1)
AWS-0104 (CRITICAL): Security group rule allows unrestricted egress to any IP address.
```

Now with the exception file:

```
docker run --rm -v ./labs/iac-security:/is aquasec/trivy:0.76.0 config /is/altyapi-duzeltilmis -q --severity CRITICAL --ignorefile /is/istisna.yaml --exit-code 1
```

The finding is gone and the exit code is **0**.

📋 Now the real question: change the `expired_at` date in `istisna.yaml` to a
date in the past and run the same command. What happens?

<details>
  <summary>Answer</summary>

Set the date to, say, `2026-01-31` and scan again:

```
Failures: 1 (CRITICAL: 1)
AWS-0104 (CRITICAL): Security group rule allows unrestricted egress to any IP address.
```

The exit code is **1** again. The finding came back and the gate closed again.

This is one of the most important mechanisms in this course. In most tools,
writing an exception silences it **indefinitely**; you write the reason as a
comment and nobody ever comes back to it. Here the deadline lives in the tool
itself: when the date passes the finding returns on its own and somebody has
to decide again.

Remembering the exception becomes the tool's job rather than a human's memory.

When you have finished the experiment, set the date back to `2027-02-28`.

</details><br/>

## Lab

Make the fixed infrastructure genuinely clean.

Edit `labs/iac-security/altyapi-duzeltilmis/main.tf` until the scan reports
**zero findings**:

```
Report Summary

┌────────┬───────────┬───────────────────┐
│ Target │   Type    │ Misconfigurations │
├────────┼───────────┼───────────────────┤
│ .      │ terraform │         0         │
└────────┴───────────┴───────────────────┘
```

What you need to do:

- give the log bucket the same protections the main bucket has
- solve the log bucket's own access-logging question — where does a bucket
  write its own logs?
- for `AWS-0104`, try **actually narrowing egress** instead of writing an
  exception
- once you reach zero, delete the entry from `istisna.yaml` and run the gate
  again — does it still pass?

> Stuck? Take a look at the [hints](hints.md) or the
> [solution](solution.md).
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

This lab ran nothing — no containers, no networks, no volumes are left behind.
Terraform was never applied either, so nothing was created in any cloud.

If you want to undo the files you changed:

```
git checkout labs/iac-security
```
