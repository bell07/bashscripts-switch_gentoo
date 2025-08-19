# Crossdev/distcc docker service for Gentoo on Nintendo Switch

The nsw-cross-distcc docker image provide cross-compiler and distcc service,
so the compiling can be speed up from nintendo switch directly or from buildhost.

## Build/Update the image
`./build-cross-distcc.sh`

Additional parameters can be passed to the docker build process:

- `--no-cache`  Repeat all build steps
- `--progress=plain` Print all output (useful in searching for bugs )

## Launch the image

`docker compose up` to launch in foreground or 

`docker compose up -d`in background

For advanced users:

```
docker run --rm --tmpfs /sys/fs/cgroup \
  -p 3632:3632 \
  -p 3633:3633 \
  nsw-cross-distcc
```

# Cleanup unused images
`docker image prune`
