# Lab Hints

As you fill in the table for `app-01`, remember this: as much as the
component's own settings, **who can connect to it** and **what it can connect
to** also produce threats. app-01 sits in the middle of this system, so it has
both sides.

These three details from the system description produce at least three threats
on their own: the password being plain text in `config.properties`, port 8080
being reachable from the internal network, and the logs sitting on the
server's own disk.

If you cannot find a row for a letter, do not force one. "There is no
repudiation threat on this component" is a valid answer — but write down why.
The difference between a letter left blank and "we looked, there is none" is
enormous for whoever reads the model six months later.

When you fill in an "Accept" in the decision section, test it like this: does
someone reading the justification understand *why* it was accepted, or only
*that* it was? "We cannot do it right now" is not a justification; "doing it
requires X, and X arrives on this date" is.

When modelling the CI/CD pipeline, the most productive question is: **who can
change the pipeline itself?** If the Jenkinsfile is in the repository, then
everyone who can write to that repository can deploy to production.

> Need more? The [solution](solution.md) is here.
