---
title: Storing Logs in Elasticsearch
lang: en
slug: elasticsearch
section: observability
order: 4
duration: 45
requires: [docker]
status: updated
upstream: labs/elasticsearch
---
# Running Elasticsearch

Elasticsearch is a document database - it uses JSON as the data format. Documents are stored in collections called indices, and the data schema is flexible so not all documents in an index need to have the same fields.

You can use Elasticsearch as a generic data store, but it's particularly well suited to storing logs because it gives you lots of advanced querying features.

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

Takes about 45 minutes.

**Docker Desktop** must be running. Check it:

```
docker version
```

A `Server:` section in the output means you are ready. If you get an error
instead, start Docker Desktop and wait until the whale icon stops animating.

> Run every command from the **root of this repository** - the paths in this lab are written relative to it.

## Reference

- [Index API](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices.html) and [Document API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs.html) documentation - for storing data
- [Search API documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-search.html) - for querying data
- [Query DSL](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html) - the data query language


## Running Elasticsearch 

Elasticsearch is a Java application. The licensing has been eventful: Elastic moved off Apache 2.0 after 7.10, then in 2024 added AGPL v3 as an option alongside SSPL and the Elastic License - so the source is OSI-approved open source again. We use the official image from Elastic's registry. 

[compose.yml](./compose.yml) sets up Elasticsearch to run in a container, publishing port 9200 which is the default port for the HTTP API.

Start the container:

```
docker compose -f labs/elasticsearch/compose.yml up -d
```

Check the logs and you'll see Elasticsearch starting up:

```
docker compose -f labs/elasticsearch/compose.yml logs elasticsearch
```

> Older versions of this lab used `docker logs <project>_<service>_1`.
> Compose v2 names containers with hyphens, not underscores, so that command
> fails with _no such container_. Asking Compose for the service's logs works
> whatever the generated container name is.

> These are semi-structured logs


We'll use curl to make HTTP requests - if you're using Windows, run this script to use the correct curl version:

```
# only for Windows - enable scripts:
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process

# then run:
. ./scripts/windows-tools.ps1
```

Now make a simple call to the Elasticsearch API:

```
curl localhost:9200
```

📋 There's some basic info in the API response. What version are we running, and what is the cluster name?

<details>
  <summary>Need some help?</summary>

The API response looks like this:

```
{
  "name" : "68d8e3d046c4",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "9yypBMAjRNC0hjMkr-FrEw",
  "version" : {
    "number" : "9.5.5",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "...",
    "build_date" : "...",
    "build_snapshot" : false,
    "lucene_version" : "...",
    "minimum_wire_compatibility_version" : "8.19.0",
    "minimum_index_compatibility_version" : "8.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

The version comes from the image tag in the Compose file - `9.5.5`. The cluster
name is `docker-cluster`, which is the default the official image uses when you
don't set one.

</details><br/>

The Elasticsearch API has a full feature set for administering the cluster and for working with documents.

## Indexing documents

Indexing is how you store data in Elasticsearch. There are [client libraries](https://www.elastic.co/guide/en/elasticsearch/client/community/current/index.html) for all the major languages, so you can integrate Elasticsearch with your application.

We'll use the REST API in these exercises - start by inserting a document into a new index:

- [fulfilment-requested.json](data/fulfilment-requested.json) - is the source data, it's a simplified version of the document processor logs from the demo fulfilment app

Index the document using an HTTP POST request:

```
curl -H 'Content-Type: application/json' -XPOST 'localhost:9200/logs/_doc' --data-binary "@labs/elasticsearch/data/fulfilment-requested.json"
```

The output includes an ID you can use to retrieve the document.

📋 What is the name of the index and the document ID?

<details>
  <summary>Need some help?</summary>

The API response looks like this:

```
{
   "_index":"logs",
   "_id":"ZODwunoBUFcX3q_Yl3rW",
   "_version":1,
   "result":"created",
   "_shards":{
      "total":2,
      "successful":1,
      "failed":0
   },
   "_seq_no":0,
   "_primary_term":1
}
```

The index name is `logs` - you don't need to create indices in advance, Elasticsearch will create them when you try to add documents.

> If you've used older Elasticsearch you may remember a `_type` field in > this response. Mapping types were removed in Elasticsearch 8.

The document ID is generated by Elasticsearch because we didn't specify an ID in the request. In this example it's `ZODwunoBUFcX3q_Yl3rW`.

</details><br/>

You can fetch the document back using an HTTP GET request - **you'll need to set your own document ID in the URL**:

```
curl localhost:9200/logs/_doc/<_id>?pretty
```

> The `?pretty` flag formats the response to make it easier to read.

This is structured data - the log level, timestamp and message data is all stored in separate fields.

📋 Add more logs by indexing two more documents, from the files in `labs/elasticsearch/data/fulfilment-completed.json` and `labs/elasticsearch/data/fulfilment-errored.json`.

<details>
  <summary>Need some help?</summary>

The POST requests are the same, only the path to the source file is different:

```
curl -H 'Content-Type: application/json' -XPOST 'localhost:9200/logs/_doc' --data-binary "@labs/elasticsearch/data/fulfilment-completed.json"

curl -H 'Content-Type: application/json' -XPOST 'localhost:9200/logs/_doc' --data-binary "@labs/elasticsearch/data/fulfilment-errored.json"
```

</details><br/>

You can use a [CAT (compact and aligned text)](https://www.elastic.co/guide/en/elasticsearch/reference/current/cat.html) API to check the index has all the documents:

```
curl localhost:9200/_cat/indices?v=true
```

> It can take a few minutes for the status to update, but you should see `docs.count` column with the value `3` for the `logs` index.

Now we have some data we can search.

## Basic searching

The simplest search in Elasticsearch is to call the `_search` endpoint on the index API, passing a search term in the querystring for the URL.

Search for the word `debug` in any document in the `logs` index:

```
curl 'localhost:9200/logs/_search?q=debug'
```

> Finds a single document, with the log level of `DEBUG` - the search is not case-sensitive.

This basic search looks in all the fields in all the documents. The response includes a `score` for each document, which is a calculation of how good a match it is for the search term.

One more simple query: adding a minus (`-`) before the search term finds any documents which _don't_ contain the term:

```
curl 'localhost:9200/logs/_search?q=-debug&pretty'
```

> Finds the other two documents, as they don't have the word `debug` in any field.


You can write more complex query expressions in JSON, using the Elasticsearch Query DSL. Here are some examples using _match queries_:

- [queries/match-all.json](queries/match-all.json) matches all documents in the index

- [queries/match-id.json](queries/match-id.json) matches all documents containing the term `21304897` in the `message` field

- [queries/match-id-level.json](queries/match-id-level.json) matches all documents containing the term `21304897` in the `message` field AND the word `INFO` in the `level` field.

Using the Query DSL with structured data lets you be more precise. If you're looking for debug logs you can search using the log level field, so you won't accidentally include documents which have the word "debug" in another field.

You send JSON queries as GET requests to the search API, using this URL format:

```
localhost:9200/<index_name>/_search?pretty=true --data-binary "@<query_file_path>"
```

📋 Run some queries to find all logs about document request ID `21304897`, and then just the info logs for that request ID.

<details>
  <summary>Need some help?</summary>

You can use the JSON files in the `queries` folder.

To find all logs for that ID:

```
curl -H 'Content-Type: application/json' localhost:9200/logs/_search?pretty=true --data-binary '@labs/elasticsearch/queries/match-id.json'
```

> Returns two matches, one info log and one debug.

To find just the info logs for that ID:

```
curl -H 'Content-Type: application/json' localhost:9200/logs/_search?pretty=true --data-binary '@labs/elasticsearch/queries/match-id-level.json'
```

> Returns a single match.

</details><br/>

There are lots of search features in Elasticsearch, so the Query DSL is quite complex. We've just had an introduction here, but it's a topic to return to if you'll be using Elasticsearch a lot.

## Lab

Time for some practice of the index and search APIs. You've loaded individual documents into an index, but it's much quicker to bulk load them.

Start by bulk indexing all the documents in the file [data/logs.json](../../data/logs.json) (_note the data directory is in the root of the repo folder_) - you'll need to use a different [Document API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs.html) for that.

Now write some match queries to find:

- how many document requests were successful?
- what was the request ID for the one error which was not a problem with the document service?

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
docker compose -f labs/elasticsearch/compose.yml down
```

> This removes only the containers this lab started. If you want
> a clean slate, `docker ps` will show anything still running.
