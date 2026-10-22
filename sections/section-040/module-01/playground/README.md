# Manage Signing Keys — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-119-playground-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

Built from the Sigstore documentation and the cosign v3.1.4 source, and not
yet run (see the repository `CLAUDE.md`). `bootstrap/prepare.sh` and the
manifests are generated; change shared pieces in every environment.

## Run it

```sh
astrona run -c .
astrona destroy ats-119-playground-040-01
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (bootstrap only) |
| `bootstrap/prepare.sh` | Environment preparation run once at startup |
| `manifests/lab-start.yaml` | Registry and workstation; `manifests/openbao.yaml`: OpenBao in development mode |
| `docs/overview.md` | What the environment contains and ideas to try |
