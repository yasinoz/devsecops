# Lab Hints

Start by reading what the finding actually says. The description of `10055` in
the ZAP report names the directives that are missing — you do not have to
guess.

The root of the problem is this: `default-src` is a *fallback* rule, but not
every directive falls back to it. Where a form submission may go, which frames
the page may embed, and where plugin content may come from all have to be
stated separately.

Directives in a CSP line are separated by semicolons. Adding the new
directives to the existing line is enough; you do not need to rewrite it.

After making the change, remember to restart the container with
`--force-recreate`, otherwise nginx keeps running with the old configuration.

In the second step you change the `10055` line in `kurallar.conf` from
`IGNORE` to `WARN`. After that we expect the gate to still pass — because the
finding no longer appears at all. If it does not pass, your CSP fix is
incomplete.

> Need more? The [solution](solution.md) is here.
