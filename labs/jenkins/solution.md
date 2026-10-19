# Lab Solution

The quickest way is to copy the job you already have:

- browse to http://localhost:8080/view/all/newJob
- set the job name to `hello-world`
- choose _Pipeline_ as the type
- in the _Copy from_ box at the bottom, enter `manual-gate`
- click _OK_

In the job config, scroll to _Triggers_ and tick **Poll SCM**. That sets a
schedule for checking the Git server for changes. Enter this in the _Schedule_
box:

```
* * * * *
```

> Five stars means every minute. Jenkins checks the repo, and if anything has
> changed since the last build it triggers a new one. Polling is wasteful
> compared to a webhook, but it works without the Git server needing to reach
> Jenkins — which is why it's still common.

Change the _Script Path_ to `labs/jenkins/hello-world/Jenkinsfile`, then save
and build. It **fails**.

Open the build and read the console output. The _Test_ stage fails with:

```
Error: Could not find or load main class HelloWorkd
```

`HelloWorkd`. That's a typo — the class is `HelloWorld`.

Fix the `java HelloWorkd` line in `labs/jenkins/hello-world/Jenkinsfile` so it
reads `java HelloWorld`. A corrected copy is in
[this Jenkinsfile](./lab/Jenkinsfile) if you want to compare.

Then commit and push:

```
git add labs/jenkins/hello-world/Jenkinsfile

git commit -m 'Fix class name typo'

git push gitea main
```

Back in Jenkins, wait up to a minute for the SCM poll to trigger the build (or
click _Build Now_ if you're impatient).

This time it passes. On the build page you'll see an **Archived Artifacts**
section containing `HelloWorld.class` — that comes from the `archiveArtifacts`
step in the `post { success { ... } }` block of the Jenkinsfile. Archiving is
how you keep the output of a build after the workspace is cleaned up.

___
> Back to the [exercises](README.md).
