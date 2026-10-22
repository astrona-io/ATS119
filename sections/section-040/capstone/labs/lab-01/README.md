---
estimated_duration: 35m
---

# Move Release Signing Into OpenBao Transit

- **ID:** CAPSTONE
- **Slug:** ats-119-capstone-040
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded capstone

Read `question.md` for the task; `solution.md` is the walkthrough. Built from
the Sigstore documentation and the cosign v3.1.4 source, and not yet run (see
the repository `CLAUDE.md`). The scripts are generated; change shared pieces in
every environment.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-119-capstone-040
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-119-capstone-040`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Environment preparation and the starting state |
| `manifests/` | Registry and workstation, OpenBao |
| `solution/apply.sh` | Reference solution used by `astrona test` |
| `testing/wait-for-workstation.sh` | Waits for the tools before the reference solution runs |
| `validation/` | Grading scripts, one per check |
