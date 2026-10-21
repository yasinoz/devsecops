# Lab Solution

The second part of the GitHub build uses the `latest` Docker Compose file:

- [release.yml](./rng/release.yml) uses different image tags, with the `RELEASE` environment variable but not the `BUILD_NUMBER` variable the main Compose file uses

When you merge in the latest file it will build images with the tag `21.05`, which is the version for this release of the app.

Consumers can use `21.05` to get the current build for this release, or e.g. `21.05-39` to get a specific build:

```
docker pull ghcr.io/yasinoz/courselabs/rng-api:21.05

docker image ls courselabs/rng-api
```

Be careful with the word *alias* here. The workflow builds the two tags in
two separate `docker compose build` runs, so they end up as separate images
even when the source is identical - compare them and the digests differ:

```
docker manifest inspect ghcr.io/yasinoz/courselabs/rng-api:21.05

docker manifest inspect ghcr.io/yasinoz/courselabs/rng-api:21.05-39
```

What matters to a consumer is the promise each tag makes: `21.05` always
gives you the current build of that release, and `21.05-39` always gives you
that exact build. With the next release the `21.05` tag moves on; the
numbered tag never does.

___
> Back to the [exercises](README.md).
