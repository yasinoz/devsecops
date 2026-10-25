---
title: Scanning the Running Application (DAST)
lang: en
slug: dast
section: security
order: 8
duration: 50
requires: [docker]
status: updated
upstream: labs/dast
---
# Scanning the Running Application (DAST)

Every security lab so far has looked at something **standing still**: static
analysis read the source code, image scanning read the packages, secret
scanning read the git history. None of them ran the application.

**DAST** (Dynamic Application Security Testing) does the opposite: it never
looks at the source, it sends requests to the running application from the
outside and looks at **what comes back**. It sees what an attacker sees.

Why is that a separate thing? Because an application's behaviour is not
necessarily what the source says. A configuration file looks right but the
server does not apply it the way you expected; a reverse proxy overwrites a
header; a setting is lost during the build. In this lab you will run into
exactly such a case — and that moment is the answer to why DAST exists.

The tool we will use is [OWASP ZAP](https://www.zaproxy.org/). Its *baseline*
scan spiders the application and passively inspects the responses; it does not
attack, which makes it fast and safe to run outside production.

<!-- outcomes:auto -->
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

## Why this lab matters

Every other security check in this course reads something that is standing still - source, packages, history. None of them runs the application, so none of them sees what the server actually sends back. A configuration can be correct in the file and wrong on the wire, and only a request to the running app tells you which.

**After this lab you will be able to:**

- scan a running application with OWASP ZAP and read the report
- tell a missing-header finding from a cookie flag and an information leak
- find a defect that passes code review but fails on one endpoint
- turn the scan into a gate with FAIL, WARN and justified IGNORE rules
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

- [OWASP ZAP — Baseline scan](https://www.zaproxy.org/docs/docker/baseline-scan/)

- [OWASP Top 10 — A05:2021 Security Misconfiguration](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/)

- [OWASP ASVS — V14 Configuration](https://owasp.org/www-project-application-security-verification-standard/)

- [NIST SSDF (SP 800-218) PW.8 — testing the software](https://csrc.nist.gov/pubs/sp/800/218/final)

## Running the application

Our target is a small order portal — a page served by nginx and a login
endpoint:

```
docker compose -f labs/dast/docker-compose.yml up -d
```

Open http://localhost:8085 in your browser and take a look. An ordinary page:
a form and a "Giris yap" link. Looking at it tells you nothing is wrong —
which is precisely the point.

## The first scan

We attach ZAP to the same Docker network as the application and run it. It
reaches the application by container name, as `uygulama`:

```
docker run --rm --network dast-net -v ./labs/dast:/zap/wrk:rw ghcr.io/zaproxy/zaproxy:2.17.0 zap-baseline.py -t http://uygulama -r rapor/rapor.html
```

The scan takes a minute or two. At the end you will see a summary like this:

```
WARN-NEW: Cookie No HttpOnly Flag [10010] x 1
WARN-NEW: Missing Anti-clickjacking Header [10020] x 3
WARN-NEW: X-Content-Type-Options Header Missing [10021] x 3
WARN-NEW: Server Leaks Version Information via "Server" HTTP Response Header Field [10036] x 5
WARN-NEW: Content Security Policy (CSP) Header Not Set [10038] x 4
WARN-NEW: Storable and Cacheable Content [10049] x 5
WARN-NEW: Cookie without SameSite Attribute [10054] x 1
WARN-NEW: Permissions Policy Header Not Set [10063] x 5
WARN-NEW: Session Management Response Identified [10112] x 2
WARN-NEW: Cross-Origin-Embedder-Policy Header Missing or Invalid [90004] x 9
FAIL-NEW: 0   FAIL-INPROG: 0   WARN-NEW: 11   WARN-INPROG: 0   INFO: 0   IGNORE: 0   PASS: 57
```

> Your numbers may move by an item or two. ZAP spiders the site first and does
> not always find exactly the same URLs on every run. The **kinds** of finding
> stay the same, and that is what matters.

The detailed report is in `labs/dast/rapor/rapor.html`. Open it in your
browser; every finding's explanation, the URL where it was seen and a
suggested fix are all in there.

📋 Look at those 11 warnings and sort them into three groups: which are
missing headers, which are about cookies, and which one leaks information?

<details>
  <summary>Answer</summary>

**Missing security headers** — response headers that tell the browser how to
treat this page are absent:

- `10020` Anti-clickjacking — the page can be placed in someone else's iframe
- `10021` X-Content-Type-Options — the browser guesses the content type
- `10038` CSP — no rule about which sources may be loaded
- `10063` Permissions Policy — capabilities like camera and location are not
  restricted
- `90004` Cross-Origin-Embedder-Policy — no cross-origin isolation

**Cookie problems** — `/giris` hands out the session cookie with no flags:

- `10010` no HttpOnly — JavaScript can read the cookie, so an XSS turns
  directly into session theft
- `10054` no SameSite — the cookie is also sent with requests from other sites

**Information leak:**

- `10036` the server announces its version with `Server: nginx/1.31.7`. Not a
  vulnerability by itself, but it tells an attacker which CVE to try.

The remaining two (`10049`, `10112`) are informational; we will come back to
them separately.

</details><br/>

Note this: **none of those findings is in the source code.** There is no flaw
in `index.html`. They are all about how the server is configured — that is,
in the place static analysis does not look.

## The first attempt at a fix

In the `labs/dast/uygulama/` folder there is a second configuration called
`nginx.guvenli.conf`. Open it and read it: every header said to be missing is
there, each one annotated with the finding it closes. The cookie has its three
flags too.

Let's attach it to the application. Open `labs/dast/docker-compose.yml` and
change the file name on this line:

```
      - ./uygulama/nginx.conf:/etc/nginx/conf.d/default.conf:ro
```

so that it reads:

```
      - ./uygulama/nginx.guvenli.conf:/etc/nginx/conf.d/default.conf:ro
```

Restart the application:

```
docker compose -f labs/dast/docker-compose.yml up -d --force-recreate
```

Run the scan again:

```
docker run --rm --network dast-net ghcr.io/zaproxy/zaproxy:2.17.0 zap-baseline.py -t http://uygulama
```

```
WARN-NEW: Missing Anti-clickjacking Header [10020] x 1
WARN-NEW: X-Content-Type-Options Header Missing [10021] x 1
WARN-NEW: Content Security Policy (CSP) Header Not Set [10038] x 1
WARN-NEW: Non-Storable Content [10049] x 6
WARN-NEW: CSP: Failure to Define Directive with No Fallback [10055] x 4
WARN-NEW: Permissions Policy Header Not Set [10063] x 1
WARN-NEW: Session Management Response Identified [10112] x 1
WARN-NEW: Cross-Origin-Embedder-Policy Header Missing or Invalid [90004] x 3
FAIL-NEW: 0   FAIL-INPROG: 0   WARN-NEW: 8   WARN-INPROG: 0   INFO: 0   IGNORE: 0   PASS: 60
```

Down from 11 to 8, and the number of passing checks went from 57 to 60. Good.

**But wait.** Anti-clickjacking is still there. X-Content-Type-Options is
still there. CSP is still there. All three of those headers are written in the
configuration file; you saw them with your own eyes.

One thing did change: it used to say `x 3`, now it says `x 1`.

📋 Which URL is that "x 1"? Find it.

<details>
  <summary>Not sure how?</summary>

Run the scan in detail; ZAP lists example URLs under each finding:

```
docker run --rm --network dast-net -v ./labs/dast:/zap/wrk:rw ghcr.io/zaproxy/zaproxy:2.17.0 zap-baseline.py -t http://uygulama -r rapor/ikinci.html
```

Under the `Missing Anti-clickjacking Header [10020] x 1` line you will see a
single URL:

```
	http://uygulama/giris (200 OK)
```

The home page was fixed. `/giris` was not.

</details><br/>

### Why `/giris` was not fixed

Look at the configuration again. There is a separate `location` block for
`/giris`, and inside it there are `add_header` lines — the cookie and cache
headers.

nginx's rule is this: **if you use `add_header` in a `location` block, that
block loses every `add_header` from the levels above it.** There is no
inheritance. Either you repeat them all in that block, or none of them apply.

Adding `always` does not save you either; `always` makes a header appear on
error responses too, and has nothing to do with inheritance.

Now think about what this bug looks like:

- Whoever reads the configuration file **sees** the headers. It passes code
  review.
- Static analysis says nothing; there is nothing badly written in the file.
- Whoever opens the home page in a browser and checks the headers sees the
  **right** answer.
- Only the user who logs in is left unprotected — that is, the request that
  most needs protecting.

The only thing that caught this bug was sending a request to **every**
endpoint of the running application and looking at the response. That is the
question DAST answers.

## The full fix

In the same folder there is `nginx.tam.conf`. The difference: the headers were
moved into a separate file called `guvenlik-basliklari.conf` and `include`d
into both the `server` and the `location` block.

Change the line in the compose file to `nginx.tam.conf`, restart, then scan:

```
docker compose -f labs/dast/docker-compose.yml up -d --force-recreate
```

```
docker run --rm --network dast-net ghcr.io/zaproxy/zaproxy:2.17.0 zap-baseline.py -t http://uygulama
```

```
WARN-NEW: Non-Storable Content [10049] x 6
WARN-NEW: CSP: Failure to Define Directive with No Fallback [10055] x 5
WARN-NEW: Session Management Response Identified [10112] x 1
FAIL-NEW: 0   FAIL-INPROG: 0   WARN-NEW: 3   WARN-INPROG: 0   INFO: 0   IGNORE: 0   PASS: 65
```

11 → 8 → 3. Passing checks 57 → 65.

The remaining three are not real defects:

- `10049 Non-Storable Content` — it is reporting that content can no longer be
  cached. The other face of the same rule; informational.
- `10112 Session Management Response Identified` — ZAP is saying it saw a
  session cookie. Informational.
- `10055 CSP: Failure to Define Directive` — this one is a genuine gap: our
  CSP defines `default-src`, but some directives such as `form-action` do not
  fall back to it and have to be written separately. That is exactly this
  lab's exercise.

> **Zero findings is not the goal.** In a real scan something always remains:
> informational rules, accepted risks, work whose turn has not come. The goal
> is for every remaining line to be a **deliberate decision**.

## The gate: making the scan stop the pipeline

A report on its own changes nothing. For the pipeline to stop, the scan has to
return a non-zero **exit code**.

Put the application back to its first (vulnerable) state — change the line in
the compose file to `nginx.conf` and restart. Then run the scan and look at
the exit code:

```
docker run --rm --network dast-net ghcr.io/zaproxy/zaproxy:2.17.0 zap-baseline.py -t http://uygulama
```

Type `echo $LASTEXITCODE` in Windows PowerShell, or `echo $?` on macOS or
Linux. You will see **2**: "there are warnings".

In that raw form it is useless. Every new informational rule breaks the
pipeline, and a week later the team switches the check off. What we need is a
threshold: a statement of **what should stop it**.

ZAP does this with a rules file. Open `labs/dast/kurallar.conf` and look —
every rule has one of three settings next to it:

- `FAIL` — stops the pipeline
- `WARN` — goes in the report, does not stop it
- `IGNORE` — does not appear at all

The ones marked `FAIL` in that file are the cookie flags and the basic
headers; the ones marked `IGNORE` have **the reason, the owner and the expiry
date** written next to them.

Run it with the rules file:

```
docker run --rm --network dast-net -v ./labs/dast:/zap/wrk:rw ghcr.io/zaproxy/zaproxy:2.17.0 zap-baseline.py -t http://uygulama -c kurallar.conf
```

```
FAIL-NEW: Cookie No HttpOnly Flag [10010] x 1
FAIL-NEW: Missing Anti-clickjacking Header [10020] x 3
FAIL-NEW: X-Content-Type-Options Header Missing [10021] x 3
FAIL-NEW: Content Security Policy (CSP) Header Not Set [10038] x 5
FAIL-NEW: Cookie without SameSite Attribute [10054] x 1
FAIL-NEW: 5   FAIL-INPROG: 0   WARN-NEW: 4   WARN-INPROG: 0   INFO: 0   IGNORE: 2   PASS: 57
```

Exit code **1**: there is at least one `FAIL`, so the pipeline stops.

Now set the compose file to `nginx.tam.conf` and run the same command again:

```
FAIL-NEW: 0   FAIL-INPROG: 0   WARN-NEW: 0   WARN-INPROG: 0   INFO: 0   IGNORE: 3   PASS: 65
```

Exit code **0**: the pipeline passes.

That is the gate. What the pipeline reads is not the report but the exit code,
and what decides which findings stop it is the rules file.

## Lab

Close the `10055 CSP: Failure to Define Directive with No Fallback` finding
that remains after the full fix — not by writing an exception but by
**actually fixing it**.

ZAP is telling you this: our CSP has `default-src`, but some directives do not
fall back to it, so the browser finds no rule for them and the policy has a
hole.

What you need to do:

- run the application with `nginx.tam.conf`
- widen the CSP line in `labs/dast/uygulama/guvenlik-basliklari.conf` so it
  covers the missing directives
- scan, and watch the `10055` finding disappear
- then change the **`IGNORE` line written for `10055` in `kurallar.conf` to
  `WARN`** and run the gate again — does it still pass?

That last step is the real point of this lab: an exception is meant to be
temporary. When the problem is fixed the exception should go too, otherwise
the next time that finding really appears nobody will see it.

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

Remove the application:

```
docker compose -f labs/dast/docker-compose.yml down
```

Make sure you have set the configuration line in the compose file back to
`nginx.conf`, so the lab starts from the beginning next time.

The generated reports are in `labs/dast/rapor/`; that folder is in
`.gitignore`, so deleting it is up to you.
