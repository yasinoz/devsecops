---
title: Visualizing Metrics with Grafana
lang: en
slug: grafana
section: observability
order: 3
duration: 40
requires: [docker]
status: updated
upstream: labs/grafana
---
# Grafana

[Grafana](https://grafana.com/oss/grafana/) is a web-based UI for visualizing data. It can consume data from many different sources, and it's particularly well matched with Prometheus. You might use the Prometheus UI to fine-tune your queries, and then you'd take the PromQL and use it in Grafana.

> The screenshots and the written steps in this lab were both taken on
> Grafana 13.2.4, the version the containers run. Menu labels do move between
> Grafana releases - if something has shifted again, the
> [Grafana docs](https://grafana.com/docs/grafana/latest/) are authoritative.

<!-- outcomes:auto -->
## Why this lab matters

Metrics nobody looks at are metrics nobody acts on. A dashboard is how a team shares one picture of the system - and building one forces you to decide which numbers actually matter.

**After this lab you will be able to:**

- connect Grafana to Prometheus as a data source
- build panels from PromQL queries and choose a visualization that fits the data
- assemble panels into a dashboard that answers a specific question
- export a dashboard as JSON so it can live in source control
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

- [Using Prometheus as a data source](https://grafana.com/docs/grafana/latest/datasources/prometheus/)
- [Panels](https://grafana.com/docs/grafana/latest/panels/) - individual query visualizations
- [Dashboards](https://grafana.com/docs/grafana/latest/panels/add-a-panel/) - combining multiple panels

## Run Grafana

Grafana is a cross-platform app, written in Go. You can [download Grafana](https://grafana.com/grafana/download?pg=get&plcmt=selfmanaged-box1-cta1) for different platforms - but we'll run in a Docker container:

- [grafana.yml](./grafana.yml) - specifies containers for Prometheus and Grafana
- [prometheus.yml](./config/prometheus.yml) - the Prometheus config we'll be using; sets up scraping for various apps, and adds the `tier` label

Run the metrics components:

```
docker compose -f labs/grafana/grafana.yml up -d
```

> Check the Prometheus status at http://localhost:9090/targets

You'll see all the targets are down, but the `tier` label is set along with `instance` and `job`. You can add to target labels like this to include infrastructure-specific details; you might include the region for cloud services, or the operating system and CPU architecture.

> Browse to Grafana at http://localhost:3000

Sign in with the default credentials - you'll be asked to create a new password, but you can skip that step:

- username: `admin`
- password: `admin`

In current Grafana you add a data source from **Connections > Data sources**:

![Grafana home screen](../../img/grafana-first-run.png)

📋 Add a Prometheus data source, with the URL `http://prometheus:9090` and test it.

<details>
  <summary>Need some help?</summary>

Open **Connections > Data sources** from the left nav and click
_Add new data source_ (or browse straight to
http://localhost:3000/connections/datasources/new).

- Select Prometheus as the data source type
- Enter `http://prometheus:9090` in the _Prometheus server URL_ field
- Leave all other fields as they are

> Click _Save & test_ and you'll see the message _Data source is working_.

</details><br/>

That's all the setup you need - now you can create a dashboard with panels to query Prometheus.

## Create an uptime panel

Open **Dashboards** from the left nav, then **New > New dashboard**. You'll see an empty dashboard like this:

![Empty dashboard](../../img/grafana-empty-dashboard.png)

Every visualization is a panel within a dashboard.

📋 Add a new panel to show the uptime of Prometheus targets using the `up` metric.

<details>
  <summary>Need some help?</summary>

The empty dashboard asks you to _Select layout_ - pick either _Auto grid_ or
_Custom grid_, then click _Add_ and choose _Panel_. (Grafana 13 replaced the
old _+ Add visualization_ button with this layout picker.) The panel editor
opens on your default data source; enter `up` in the query editor. You'll see
a preview of the visualization, which is not quite what we want:

![Default time series preview of the up metric](../../img/grafana-up-preview.png)

</details><br/>

The panel designer is in three sections:

- visualization preview at the top
- data on the bottom, including the query and transforms
- display options on the right, including visualization type

The defaults are to use a _Time series_ visualization, representing a range vector from Prometheus.

Now it's time to find your way around :) 

📋 Change the panel setup so Grafana treats this as a table showing an instant vector, using a table visualization. Set up the table so the instance name and status are the only fields, showing `ok` for instances which are up and `OFFLINE` for others.

Here's what you're aiming for:

![Target uptime as a table with ok/OFFLINE value mappings](../../img/grafana-uptime-table.png)

<details>
  <summary>Need some help?</summary>

In the _Query_ panel:

- set _Format_ to Table
- set _Type_ to Instant

> In Grafana 13 these live under _Options_ in the query row. _Instant_ used to
> be a checkbox; it is now one of the two _Type_ choices (Range or Instant).

In the display options:

- change type to Table

In the _Transformations_ tab (next to _Query_):

- Select _Organize fields by name_ 
    - hide all except instance and value
    - rename value to Status

Back in display options:

- Add a title

- scroll to _Value mappings_ and click _Add value mappings_ (the button reads
  _Edit value mappings_ once you have some)
    - add a mapping for value=0 to display `OFFLINE` 
    - add a mapping for value=1 to display `ok`
    - click _Apply_

Click _Back_ at the top-right to return to the dashboard, then _Save_ to keep
it. (Both buttons were named _Back to dashboard_ and _Save dashboard_ in
older Grafana.)

</details><br/>

Grafana dashboards can be set to auto-refresh. Select to refresh every 5 seconds (top-right of the dashboard), so when we start the apps you'll see the table update as they come online.

## Visualization Types

Start the apps, so Prometheus will have some metrics to collect:

- [apps.yml](./apps.yml) - specifies the node exporter, document API and three document processors; one of the processors is configured to keep exiting and restarting.

Run the apps:

```
docker compose -f labs/grafana/apps.yml up -d
```

> Switch back to Grafana - you'll see  the table update as instances come online.

If you watch long enough you'll see processor instance 1 flicks between `ok` and `OFFLINE`. The table we have shows the current status, and it would also be useful to see the history of each component's uptime.

Click _Add_ in the top menu and choose _Panel_ to add a second panel.

Last time we used a transform to hide labels, but we can do that in the query too:

- set the query to be `sum without(job, tier) (up)`
- change the visualization type to _State timeline_
- add the same value mapping to show 0 as `OFFLINE` and 1 as `ok`
- change the time range to (e.g.) last 15 minutes

We're getting there, just some tidying up to do.

📋 Edit the query and display options so the legend on the y-axis is more useful, hide the x-axis legend, and show `OFFLINE` as a red bar and `ok` as green.

This is the goal:

![Target uptime as a state timeline, green for ok and red for OFFLINE](../../img/grafana-uptime-timeline.png)

<details>
  <summary>Need some help?</summary>

In the display options:

- add a panel title

- scroll to  _Legend_
    - set _Legend mode_ to _Hidden_

- scroll to  _Thresholds_ 
    - set the base value to the colour red
    - set the next threshold to 1 and the colour green

In the query panel:

- set the legend format to `{{instance}}`

Click _Back_.

</details><br/>

That's better - the dashboard now shows current and historical status for all the instances. We can see there's a recurring problem with processor 1, which isn't clear from the table alone.


## A Real Dashboard

Grafana can be fiddly to work with - but once you have your dashboard designed, you can load it into any Grafana server.

In the lab we'll carry on with a custom dashboard, but so you can see what a real dashboard looks like, there's one stored in the file `labs/grafana/dashboards/app.json` you can load:

- open **Dashboards** from the left nav, then **New > Import**
- click _Upload dashboard JSON file_ and navigate to the path for the
  `app.json` file
- select your Prometheus data source if you are prompted, then click _Import_

These visualizations are all powered by the metrics from the container apps you have running. You can reduce the timescale from the dropdown in the top-right and show metrics from the last 30 minutes to see how Grafana shows trends.

## Lab

You'll have several dashboards for your apps, showing information at different levels.

For this lab we'll stick with instance uptime, but your job is to split the dashboard into multiple rows, one for each tier of the application:

- an infrastructure row with the node exporter instance
- a web row with the document API instance
- a backend row with the processor instances

Each row should have a current status table and an timeline for the instances in that tier, something like this:

![Uptime dashboard split into infrastructure, web and backend rows](../../img/grafana-uptime-dashboard.png)

Save your dashboard as JSON so you can load it into another Grafana instance later.

> Stuck? Try [hints](hints.md) or check the [solution](solution.md).

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

Clean up by removing this lab's containers:

```
docker compose -f labs/grafana/grafana.yml down
docker compose -f labs/grafana/apps.yml down
```

> This removes only the containers this lab started. If you want
> a clean slate, `docker ps` will show anything still running.
