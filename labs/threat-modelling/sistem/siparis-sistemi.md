# Order System — current architecture

This is the system we are going to model. It is the enterprise version of the
order service you have seen in the labs throughout this course.

## Today's setup (virtual machines)

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

**Known details:**

- httpd on `web-01` starts as `root`, then drops to the `apache` user
- `app-01` connects to the database as `siparis_app`; the password is in the
  application's `config.properties` in plain text
- `sql-01` is reachable only from the internal network — but from **all** of
  the internal network
- Backups are taken nightly as a LUN copy on the SAN, unencrypted
- Administrators connect directly to all three VMs over RDP/SSH
- Patching is done by hand in the monthly maintenance window
- Logs stay on each server's own disk for 30 days

## Target setup (containers)

The same system, moved onto the stack you built during this course:

```
  Internet
     │
     ▼
┌──────────────────────────────────────┐
│  Kubernetes cluster                  │
│                                      │
│  ┌────────┐   ┌────────┐   ┌──────┐ │
│  │ ingress│──▶│  app   │──▶│ sql  │ │
│  │        │   │(3 reps)│   │(stf) │ │
│  └────────┘   └────────┘   └──────┘ │
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

**Known details:**

- Images are built in the CI pipeline and pushed to the registry
- Deployment to the cluster is via GitOps; the manifest lives in a git
  repository
- The database password is in a Kubernetes `Secret`
- Cluster access is with `kubectl`, authenticated against the corporate
  directory
- Logs stream to a central collector
- Patching means rebuilding and redeploying the image
