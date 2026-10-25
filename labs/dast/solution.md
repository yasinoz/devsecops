# Lab Solution

Find the CSP line in `labs/dast/uygulama/guvenlik-basliklari.conf`:

```
add_header Content-Security-Policy "default-src 'self'; frame-ancestors 'none'" always;
```

Add the directives that do not fall back to `default-src`:

```
add_header Content-Security-Policy "default-src 'self'; frame-ancestors 'none'; form-action 'self'; frame-src 'none'; object-src 'none'; base-uri 'self'" always;
```

Each addition closes a separate hole:

| Directive | What it prevents |
|---|---|
| `form-action 'self'` | The form being submitted to another site. Even if an attacker injects a form into the page, the data cannot leave. |
| `frame-src 'none'` | The page embedding another site in a frame. |
| `object-src 'none'` | Plugin content being loaded with `<object>` and `<embed>`. An old attack surface that still works. |
| `base-uri 'self'` | A `<base>` tag redirecting every relative link to another server. |

Recreate the container and scan:

```
docker compose -f labs/dast/docker-compose.yml up -d --force-recreate
```

```
docker run --rm --network dast-net ghcr.io/zaproxy/zaproxy:2.17.0 zap-baseline.py -t http://uygulama
```

```
WARN-NEW: Non-Storable Content [10049] x 6
WARN-NEW: Session Management Response Identified [10112] x 1
FAIL-NEW: 0   FAIL-INPROG: 0   WARN-NEW: 2   WARN-INPROG: 0   INFO: 0   IGNORE: 0   PASS: 66
```

`10055` is gone. Passing checks went from 65 to 66.

## Second step: removing the exception

Find the `10055` line in `labs/dast/kurallar.conf`:

```
10055	IGNORE	(CSP)	CSP'yi kademeli siklastiriyoruz; form-action/frame-src bir sonraki surumde. Sahibi: portal ekibi, son tarih 2026-12-31.
```

Change `IGNORE` to `WARN` and delete the justification — no justification is
needed any more, the problem is fixed:

```
10055	WARN	(CSP)
```

Run the gate:

```
docker run --rm --network dast-net -v ./labs/dast:/zap/wrk:rw ghcr.io/zaproxy/zaproxy:2.17.0 zap-baseline.py -t http://uygulama -c kurallar.conf
```

```
FAIL-NEW: 0   FAIL-INPROG: 0   WARN-NEW: 0   WARN-INPROG: 0   INFO: 0   IGNORE: 2   PASS: 66
```

Exit code **0**. The gate passes, and it no longer carries an exception for
`10055`.

## What this is really teaching

An exception line is one of two things:

- **A decision.** "We accept this for now, here is why, here is the owner, we
  will look again on this date."
- **A forgetting.** "This finding was annoying, silence it."

The two look **exactly the same** in the file. The only thing that tells them
apart is the justification written next to it and somebody actually coming
back on that date.

In this lab we fixed the problem and removed the exception. What if we had not
removed it? If the CSP were accidentally loosened later, `10055` would appear
again — but because the rules file still said `IGNORE`, **nobody would see
it**. The gate would look like it was standing there while in fact it was
blind on that subject.

> For every finding you fix, remove its exception too. Unless it is cleaned
> up, an exception list gradually turns into a list of the scanner's blind
> spots.

___
> Back to the [exercises](README.md).
