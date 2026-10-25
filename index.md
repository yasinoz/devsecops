---
title: DevSecOps Labs
lang: en
slug: index
section: index
order: 0
status: updated
upstream: index.md
---
# DevSecOps Labs

Hands-on labs for DevOps and DevSecOps practices. Everything runs on your own
machine with Docker — no cloud account, no credit card.

> 🇹🇷 [Türkçe sürüm](index.tr.md)

## Pre-reqs

Work through these **before** the first lab:

1. **[Set up your environment](setup/README.md)** — Docker, Git and a terminal.
2. **Get the labs:**

   ```
   git clone https://github.com/yasinoz/devsecops.git
   cd devsecops
   ```

3. **Sign in to Docker Hub** (free account). This is not optional in a
   classroom: Docker Hub limits anonymous image pulls *per IP address*, so
   twenty students sharing one office connection will hit the limit and see
   `toomanyrequests` halfway through a lab.

   ```
   docker login
   ```

4. _Optional but recommended_ — [Visual Studio Code](https://code.visualstudio.com)
   to browse the repo and edit files.

Some labs in the last section need a **Kubernetes cluster**. The setup guide
covers the options; the simplest is enabling Kubernetes in Docker Desktop.

<!-- labs:start -->

## CI/CD Pipeline

Build automation with Jenkins, container images and release pipelines.

| Lab | Time | Needs |
|---|---|---|
| [Automation with Jenkins](labs/jenkins/README.md) | 45 min | docker |
| [Building Container Images](labs/images/README.md) | 40 min | docker |
| [Accessing Images on Registries](labs/registries/README.md) | 30 min | docker |
| [Multi-Stage Builds](labs/multi-stage/README.md) | 40 min | docker |
| [Building Apps with Compose](labs/compose-build/README.md) | 45 min | docker |
| [Building Docker Images with Jenkins](labs/pipeline/README.md) | 60 min | docker |

## Observability

Metrics, logs and distributed traces - knowing what your system is doing.

| Lab | Time | Needs |
|---|---|---|
| [Collecting Metrics with Prometheus](labs/prometheus/README.md) | 45 min | docker |
| [Exporting Metrics](labs/prometheus/metrics/README.md) | 40 min | docker |
| [Visualizing Metrics with Grafana](labs/grafana/README.md) | 40 min | docker |
| [Storing Logs in Elasticsearch](labs/elasticsearch/README.md) | 45 min | docker |
| [Searching Logs with Kibana](labs/kibana/README.md) | 45 min | docker |
| [Distributed Tracing](labs/tracing/README.md) | 45 min | docker |
| [Visualizing Traces with Jaeger](labs/jaeger/README.md) | 35 min | docker |

## Security in Depth

Shifting security left - static analysis, scanning, golden images and policy enforcement.

| Lab | Time | Needs |
|---|---|---|
| [Static Code Analysis](labs/static-analysis/README.md) | 45 min | docker |
| [Security Scanning](labs/scanning/README.md) | 45 min | docker |
| [Golden Image Libraries](labs/golden-images/README.md) | 50 min | docker |
| [GitOps with ArgoCD](labs/argo/README.md) | 60 min | docker, kubernetes |
| [Enforcing Workload Policies](labs/admission/README.md) | 60 min | docker, kubernetes |
| [Container Security Controls](labs/container-security/README.md) | 50 min | docker, kubernetes |
| [Secret Scanning](labs/secret-scanning/README.md) | 40 min | docker |
| [Scanning the Running Application (DAST)](labs/dast/README.md) | 50 min | docker |
| [Infrastructure as Code Security](labs/iac-security/README.md) | 45 min | docker |
| [Threat Modelling Workshop](labs/threat-modelling/README.md) | 60 min | - |

<!-- labs:end -->

## How a lab works

Every lab follows the same shape:

- **Reference** — links to the real documentation. Use these at work, not the lab.
- **Walkthrough** — guided steps. Commands are copy-pasteable.
- 📋 **Tasks** — you work these out yourself. The answer is hidden in a
  `Not sure?` block right underneath, so try first and then check.
- **Lab** — a harder exercise with no walkthrough. `hints.md` nudges you,
  `solution.md` gives the answer.
- **Cleanup** — always run it, or the next lab will fight for the same ports.

## Status and known gaps

The labs were modernised from a 2021 source; see
[MODERNIZASYON.md](MODERNIZASYON.md) for exactly what changed, what is verified,
and what still needs a hands-on run. Labs marked `beta` on the website have
been updated but not yet run end to end.

Found something broken? Open an issue — that is genuinely useful, because a
lab that fails in class is worse than no lab.

## Credits

Derived from [courselabs/devsecops](https://github.com/courselabs/devsecops) by
[Elton Stoneman](https://github.com/sixeyed), used and redistributed under
CC BY-SA 4.0. See [ATTRIBUTION.md](ATTRIBUTION.md).

Turkish translation, modernisation and lab tooling by
[Mehmet Yasin Özkasapoğlu](https://github.com/yasinoz) — `sudo2go`.
