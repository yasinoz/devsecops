---
title: Secret Scanning
lang: en
slug: secret-scanning
section: security
order: 2
duration: 40
requires: [docker]
status: updated
upstream: labs/secret-scanning
---
# Secret Scanning

Passwords, API keys, connection strings — we call these *secrets*, and they
should not live in source code. But they do. Someone in a hurry writes the key
into a config file, thinks "I'll fix it later", and commits it.

Here is the real problem: **once a secret is in git, deleting it does not take
it back.** Remove it from the file and commit, and the working tree is clean
while the history is not. Anyone who types `git log -p` can read that key. If
the repository was ever cloned, it is now on somebody else's disk too.

[gitleaks](https://github.com/gitleaks/gitleaks) looks for exactly this: it
scans the working tree *and* **the whole history**, flagging anything that
looks like a secret. In this lab we will first find the leak, then build the
gate that stops the next one.

<!-- outcomes:auto -->
## Why this lab matters

A secret that reaches git is not removed by deleting it - the working tree gets clean, the history does not, and anyone who cloned the repository already has a copy. So this is not a tidying job but a rotation job, and the only real fix is a gate that stops the secret from ever being committed.

**After this lab you will be able to:**

- scan a repository's whole history, not just the files on disk
- read a finding and tell which key was leaked and where
- block a secret before the commit, using the exit code as the gate
- narrow an exception to a single finding instead of skipping a file
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

Takes about 40 minutes.

**Docker Desktop** must be running. Check it:

```
docker version
```

A `Server:` section in the output means you are ready. If you get an error
instead, start Docker Desktop and wait until the whale icon stops animating.

> Run every command from the **root of this repository** - the paths in this lab are written relative to it.

## Reference

- [gitleaks repository and rule list](https://github.com/gitleaks/gitleaks)

- [OWASP — Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

- [NIST SSDF (SP 800-218) PW.4 and PW.9 — code integrity and configuration](https://csrc.nist.gov/pubs/sp/800/218/final)

## Creating the leaky repository

To study a real leak we need a real history. The small image in the
[demo folder](./demo/Dockerfile) produces one — a three-commit repository with
an AWS secret in the second commit and a "cleaned up" version in the third.

Build the image first:

```
docker build -t sirli-depo ./labs/secret-scanning/demo
```

Then create the repository:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo sirli-depo
```

The repository now lives in the `labs/secret-scanning/sirli-depo` folder. You
can open it in your own editor — in this lab we will write a few files by
hand, and all of them go in that folder.

> ⚠️ **On Windows, run these commands in PowerShell.** Git Bash rewrites the
> `/depo` part of `-v ... :/depo` into a Windows path and breaks it (you get
> `invalid volume specification`). PowerShell has no such problem.

## Scanning the working tree

Let's look at the files we have. The `dir` command never opens git; it only
scans what is on disk:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo zricethezav/gitleaks:v8.30.1 dir /depo --no-banner
```

The last line of the output:

```
INF no leaks found
```

Clean. That is what the report says, so there is no problem — **is there?**

## Scanning the history

Now look at the same repository from the git side. The `git` command walks
every commit's diff:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo zricethezav/gitleaks:v8.30.1 git /depo --no-banner -v
```

This time there is a finding:

```
Finding:     aws_secret_access_key: 7Hk2pQnR4vTzL9mXbW3dYfJ6gC8sA1eU5oI0rNtP
Secret:      7Hk2pQnR4vTzL9mXbW3dYfJ6gC8sA1eU5oI0rNtP
RuleID:      generic-api-key
Entropy:     5.321928
File:        config.yml
Line:        5
Commit:      ea9ceaadc754e297f774db4855aab331ae473cbb
Author:      Lab
Email:       lab@example.com
Date:        2026-10-24T20:27:11Z
Fingerprint: ea9ceaadc754e297f774db4855aab331ae473cbb:config.yml:generic-api-key:5
```

> Your `Commit` and `Fingerprint` values will differ — the repository is built
> on your machine, so the commit ids change every time. We will use this
> shortly, so keep the output open.

The difference between those two scans is this entire lab: **looking at the
files is not enough, you have to look at the history.** The developer deleted
the secret, committed, and thought the job was done. The key is still there.

📋 Confirm for yourself that the key really is in the history.

<details>
  <summary>Not sure how?</summary>

You can read the repository's git history directly. You do not need git
installed on your machine — we use the one inside the demo image:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo --entrypoint git sirli-depo -C /depo log -p -- config.yml
```

In the second commit's diff you will see the key in plain text. The third
commit removes it, but that removal is itself part of the history — the old
version is still readable from there.

</details><br/>

### What to do when you find a leak

The reflex here is usually wrong. People say "let's clean the history" and
rewrite the commits with `git filter-repo`. That is the **second** step, and
an optional one.

**The first step is always to rotate the key.** From the moment a secret
enters a repository even once, it is burnt: you do not know who cloned it,
whose CI cache kept it, or which backup it landed in. Cleaning the history
does not invalidate the key — it only makes it harder to find.

So the order is:

1. revoke the key at the provider and issue a new one
2. put the new key in a secret store, not in code
3. read the access logs — what was done with that key
4. *then*, if you want to, rewrite the history

## The secret the scanner did not see

There is a file called `docs/ornek.md` in the repository. Open it in your
editor and look inside — `labs/secret-scanning/sirli-depo/docs/ornek.md`.

There are two AWS keys sitting there. Yet neither scan reported them. Why?

Because `AKIAIOSFODNN7EXAMPLE` and `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`
are the **example** keys from AWS's own documentation. Gitleaks' default
configuration has an allowlist, and they are on it. The scanner is saying
"every README on earth contains this key, it cannot be real".

That is the right call — otherwise every documentation file would raise a
false alarm. But it also teaches you this:

> **"The scanner said clean" and "there are no secrets" are not the same
> statement.** Every scanner has an allowlist, a rule set and a threshold. It
> finds what it can see, and nothing else.

📋 How does this backfire in your own organisation? Think about your own key
format not being in the default rules.

<details>
  <summary>Answer</summary>

Gitleaks knows the key formats of **well-known** providers: GitHub, AWS,
Stripe, Slack. It does not know your own format, something like
`SPS-4K7M2Q9XB3TR6WZA` — if it happens to have high entropy it may trip the
`generic-api-key` rule, and if not it is invisible.

For your own formats you have to write your own rule. The exercise at the end
of this lab is exactly that.

</details><br/>

## Stopping it before the commit

Finding it is good, but what we actually want is for the secret **never to
enter the history**. For that, gitleaks can look at changes that are staged
but not yet committed.

First stage a secret. With your editor, create a file called `ci.yml` inside
the `sirli-depo` folder and put this in it:

```
ci:
  token: ghp_K3nR7pQ2vXz9LmW4bYdF6gJ8sC1aU5oI0rNt
```

> That token is fake and connected to nothing — its shape resembles a real
> one, which is all gitleaks needs in order to recognise it.

Stage the file for commit:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo --entrypoint git sirli-depo -C /depo add ci.yml
```

Now run the gate:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo zricethezav/gitleaks:v8.30.1 git /depo --staged --no-banner -v
```

```
Secret:      ghp_K3nR7pQ2vXz9LmW4bYdF6gJ8sC1aU5oI0rNt
RuleID:      github-pat
WRN leaks found: 1
```

This time the rule is `github-pat`, not `generic-api-key`. Gitleaks can tell
from the token's shape which service it belongs to — which is far more useful
for whoever reads the finding: they know which key to rotate.

The important part: **the commit has not happened.** The secret never entered
the history.

📋 What has to be true for this command to work as a gate?

<details>
  <summary>Answer</summary>

The exit code has to be non-zero. Automation does not read reports, it reads
exit codes. Run the command without `-v` and look at the exit code:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo zricethezav/gitleaks:v8.30.1 git /depo --staged --no-banner
```

Type `echo $LASTEXITCODE` in Windows PowerShell, or `echo $?` on macOS or
Linux — you will see `1`. With no leaks it returns `0`.

That is what lets you put the command in a `pre-commit` hook or a CI job: if
it returns `1`, the commit or the build stops. What makes a gate a gate is not
the report, it is this exit code.

</details><br/>

Unstage the secret again; the repository needs to stay clean:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo --entrypoint git sirli-depo -C /depo restore --staged ci.yml
```

Then delete `ci.yml` from the folder.

## Exceptions: silencing a finding you already know about

Not every finding is a real secret. Test data, example configuration, a key
that was rotated long ago — these come back at every scan, and after a while
nobody reads the report any more. Noise is the most common reason a gate gets
switched off.

In gitleaks an exception is made by writing the finding's **fingerprint** into
a file. Get your own fingerprint first:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo zricethezav/gitleaks:v8.30.1 git /depo --no-banner -v
```

Copy the `Fingerprint:` line. It looks like this, but yours will differ:

```
ea9ceaadc754e297f774db4855aab331ae473cbb:config.yml:generic-api-key:5
```

📋 Write that fingerprint into a `.gitleaksignore` file at the root of the
repository and scan again.

<details>
  <summary>Not sure how?</summary>

With your editor, create a file called `.gitleaksignore` in the `sirli-depo`
folder and write your own fingerprint as a single line:

```
ea9ceaadc754e297f774db4855aab331ae473cbb:config.yml:generic-api-key:5
```

Then scan again:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo zricethezav/gitleaks:v8.30.1 git /depo --no-banner
```

You see `no leaks found`, and the exit code is now `0`.

</details><br/>

The fingerprint contains the commit id, the file, the rule and the line
together. So the exception is specific to **that finding**: if a new secret
lands in the same file the fingerprint changes and the gate closes again. That
is a far narrower exception than saying "never scan this file".

> An exception entry is a decision, not a cleanup. Write down the reason, the
> owner and the expiry date next to it. A finding silenced quietly is a
> finding forgotten.

Delete the `.gitleaksignore` file before moving on.

## Lab

Gitleaks does not know your organisation's key format. Your turn to teach it.

The order-processing service's own API keys start with `SPS-` followed by 16
uppercase letters and digits — for example `SPS-4K7M2Q9XB3TR6WZA`. Put a key
like that into the repository and make gitleaks catch it.

What you need to do:

- add a file containing a key in that format to the `sirli-depo` folder
- scan first — see that the default rules **do not** catch it
- write a `.gitleaks.toml` in the same folder defining your own rule
- scan again, and see your own rule name in the finding's `RuleID` field

There is one thing to watch out for: when you write your own configuration
file, gitleaks may **stop using** the default rules. So while adding your own
rule, make sure you do not lose the ones that catch GitHub and AWS keys.

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

Remove what this lab created:

```
docker rmi sirli-depo
```

The demo repository is in the `labs/secret-scanning/sirli-depo` folder. That
folder is in `.gitignore`, so it does not pollute your repository; delete it
or leave it as you prefer — running the lab again rebuilds it from scratch.
