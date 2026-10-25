# Lab Solution

Give the log bucket the equivalents of what the main bucket has, and narrow
egress. Add this to `altyapi-duzeltilmis/main.tf`:

```
# Encryption for the log bucket - uses the same KMS key.
resource "aws_s3_bucket_server_side_encryption_configuration" "arsiv_kayitlari" {
  bucket = aws_s3_bucket.arsiv_kayitlari.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.arsiv.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "arsiv_kayitlari" {
  bucket = aws_s3_bucket.arsiv_kayitlari.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "arsiv_kayitlari" {
  bucket = aws_s3_bucket.arsiv_kayitlari.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# The log bucket writes its own logs to itself.
resource "aws_s3_bucket_logging" "arsiv_kayitlari" {
  bucket        = aws_s3_bucket.arsiv_kayitlari.id
  target_bucket = aws_s3_bucket.arsiv_kayitlari.id
  target_prefix = "kendi/"
}
```

Narrow the security group's egress rule as well:

```
  egress {
    description = "Yalnizca sirket vekil sunucusuna HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.30.0.0/16"]
  }
```

Scan:

```
docker run --rm -v ./labs/iac-security:/is aquasec/trivy:0.76.0 config /is/altyapi-duzeltilmis -q
```

```
Report Summary

┌────────┬───────────┬───────────────────┐
│ Target │   Type    │ Misconfigurations │
├────────┼───────────┼───────────────────┤
│ .      │ terraform │         0         │
└────────┴───────────┴───────────────────┘
```

Zero findings. Then delete the `AWS-0104` entry from `istisna.yaml` and run
the gate — exit code `0`, because the finding no longer appears at all. The
exception is no longer needed.

## The log bucket logging itself

In the solution above the log bucket writes its own access logs **to itself**.
That satisfies the scanner and breaks the infinite chain of buckets, but there
is a side you should know about:

- it produces logs about logs, so the bucket grows by itself
- anyone with access to the bucket can also delete their own trace — which was
  the entire point of the audit log

Real setups send **logs to a separate account** instead; nobody in the
production account has any permission beyond writing. In that architecture
this Terraform file contains no log bucket at all, and the target is a bucket
in another account.

So "zero findings" here does not mean "the architecture is right". The scanner
says it is clean against its own rule list; the design questions the rules do
not cover are still yours.

> A scanner returning zero does not mean the questions worth asking have run
> out. It only means the questions that tool knows about have run out.

___
> Back to the [exercises](README.md).
