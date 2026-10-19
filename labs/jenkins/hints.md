# Lab Hints

Your new job will look a lot like the `manual-gate` job you just created — it's
the same kind of job pointing at a different script path. It would be a shame to
type it all again, so look for a way to copy an existing job when you create
the new one.

The build trigger you want is under _Triggers_ in the job config. You're looking
for the one that asks the Git server whether anything has changed, on a
schedule.

When the build runs it produces a lot of console output. The failure is in
there — read the log for the stage that went red rather than scrolling to the
bottom.

Once you fix the Jenkinsfile you'll need to commit and push. If your trigger is
set up correctly you don't have to click anything; the next poll picks up the
change and starts a build.

> Need more? Here's the [solution](solution.md).
