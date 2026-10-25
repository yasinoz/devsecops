# Lab Hints

You can read which resource the remaining findings belong to from the output.
Trivy prints the file name, the line number and the code snippet under each
finding — look at the line numbers, they all point to the same place.

For every protection you gave the main bucket, the log bucket needs an
equivalent: the encryption configuration, versioning, the public-access block.
Repeating the blocks you already wrote for the second bucket is enough — you
only change the `bucket` field and the resource name.

The log bucket's own access logging takes a moment's thought: if logs are
written to a bucket, where do that bucket's logs go? You cannot keep creating
new buckets forever. You have to stop somewhere, and Terraform will not stop
you.

For `AWS-0104`, look at the `cidr_blocks` field. You narrowed the port, but
that field still says "anywhere". Think about where egress actually needs to
go — something concrete, like the company proxy's range.

In the last step, when you delete the entry from `istisna.yaml` the gate
should still pass; if it does not, your `AWS-0104` fix did not hold.

> Need more? The [solution](solution.md) is here.
