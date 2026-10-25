# Lab Solution

In the `sirli-depo` folder create a file called `entegrasyon.yml` and put
this in it:

```
entegrasyon:
  anahtar: SPS-4K7M2Q9XB3TR6WZA
```

Scan with the default rules first:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo zricethezav/gitleaks:v8.30.1 dir /depo --no-banner
```

```
INF no leaks found
```

The key is sitting right there and gitleaks does not see it. The `SPS-`
format is not in the default rule list, and it does not cross the entropy
threshold either.

Now create a `.gitleaks.toml` file in the same folder:

```
[extend]
useDefault = true

[[rules]]
id = "siparis-servisi-anahtari"
description = "Siparis servisi API anahtari"
regex = '''SPS-[A-Z0-9]{16}'''
```

Scan again:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo zricethezav/gitleaks:v8.30.1 dir /depo --no-banner -v
```

```
Secret:      SPS-4K7M2Q9XB3TR6WZA
RuleID:      siparis-servisi-anahtari
WRN leaks found: 1
```

The `RuleID` field now carries your own rule name. Whoever reads the finding
can see straight away which system's key leaked.

## Why `[extend]` is there

This is what the exercise is really teaching. If you write the configuration
file without the `[extend]` section, gitleaks uses **only your rule** and
drops every built-in one.

To see the difference, keep a GitHub token in the repository as well — put
`ci.yml` back:

```
ci:
  token: ghp_K3nR7pQ2vXz9LmW4bYdF6gJ8sC1aU5oI0rNt
```

Delete the `[extend]` section and scan:

```
RuleID:      siparis-servisi-anahtari
WRN leaks found: 1
```

One finding. The GitHub token **got through**.

Now put the `[extend]` section back and scan:

```
RuleID:      github-pat
RuleID:      siparis-servisi-anahtari
WRN leaks found: 2
```

Two findings. By adding your own rule you are **extending** the built-in ones
rather than replacing them.

In the field this mistake looks like this: a team writes a rule for its own
key format, the scan runs, a finding comes back, and everybody concludes the
system works. Meanwhile, from that day on, AWS and GitHub keys are never
checked. The scanner runs, the gate stands, but the coverage quietly shrank.

> Every time you change the configuration, check that **something that used to
> be caught is still caught.** Shrinking coverage is silent; it does not throw
> an error.

___
> Back to the [exercises](README.md).
