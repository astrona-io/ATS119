# Get Your Machine Ready

Every playground and lab in this course runs on your own machine, in a small Kubernetes cluster. A tool called `astrona` builds it for you, sets it up, grades your work and removes it again. This page gets your machine ready: first the tools you need, then the handful of `astrona` commands you will use every day, and last what to do when a start goes wrong.

## What you need

Your own machine needs very little, because every Sigstore tool runs inside the cluster. Install these before you start:

- **A container engine:** Docker or Podman. The cluster runs inside it.
- **`kind`:** runs Kubernetes inside the container engine.
- **`kubectl`:** talks to the cluster, and opens a shell in the workstation pod.
- **The astrona command-line tool.**

You do not install `cosign`, `syft` or the other tools yourself. The **workstation** pod in each environment downloads pinned versions when it starts: `cosign` v3.1.4, `rekor-cli`, `gitsign`, `regctl` and `syft` v1.55.0, plus `git`, `curl`, `jq` and `openssl`. So the playgrounds and labs need **outbound internet** while they start, to download those tools from GitHub and the example images from `ghcr.io`. Without it, a start fails with download errors that have nothing to do with Sigstore.

## Working in the workstation

Almost every command in this course runs in the workstation. Open a shell in it like this:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

The shell starts in `/work`, a folder that keeps your files while the pod runs. Most pages begin with three lines that set the values they use: the key password, the repository of the example image, and the signing configuration. The key password `lab-only-password` is for these labs only; a real key gets a strong password of its own.

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
```

The variable `REGISTRY` is already set in the workstation to `registry.localtest.me:5001`, the registry inside the cluster. That registry uses plain HTTP, which is fine for a lab and never for real images, so `cosign` commands that talk to it carry the flag `--allow-http-registry`.

You do not have to check your tools by hand. Let `astrona` look at your machine for you:

```sh
astrona setup
```

`astrona setup` looks at what is missing, shows you each step it would take, and asks before it does anything. On macOS it can install `kind`, `kubectl` and Podman.

Later, you can check your machine at any time:

```sh
astrona check
```

## The commands you use every day

Once your machine is ready, you need only a handful of `astrona` commands. Each module page and lab page shows the exact command to copy, so you do not need to remember paths. This section walks through them in the order you meet them: sign in, start, pause, submit and clean up.

Labs from the course catalog are tied to your Astrona account, so you sign in first:

```sh
astrona login
```

Next you start a playground or a lab. Each module page and lab page shows the exact `astrona run` command for it. It looks like this:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-010/module-01/playground
```

When the cluster is ready, `kubectl` already points at it.

A chapter that sends you to a lab asks you to pause the playground first. Pausing frees your machine's memory but keeps everything you built:

```sh
astrona stop <name>
```

When the lab is done, start the playground again and carry on where you left off:

```sh
astrona start <name>
```

Inside a lab, you send your work for grading with `astrona submit`. The grader checks the live cluster. It runs `cosign verify` and its relatives with its own copy of the public key, so your signatures have to actually verify, not only exist. Each lab page shows the exact command:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

You can submit as often as you like.

When you are done with a playground or a lab, remove it:

```sh
astrona destroy <name>
```

The name is the environment's name, printed by `astrona run` and shown on each page (for example `ats-119-playground-010-01`). It is not the folder path. To see what is on your machine, list it:

```sh
astrona list
```

> [!WARNING]
> **Run one environment at a time.** Each playground and lab is a whole cluster with its own registry and workstation. Two running at once can use up your machine's memory, and it is easy to send a command to the wrong one. Pause or destroy the playground before you start the lab.

## When a start goes wrong

Sometimes a playground or lab does not start cleanly. Ask `astrona` what is wrong before you try anything else:

```sh
astrona doctor
```

It checks your machine, the lab's configuration and the running lab, and tells you how to fix what it finds.

If a start fails while it downloads something, check your network first. If `kubectl exec` says the workstation is not ready, wait a minute: it downloads its tools when it starts. Remember also that a lab that starts with a signature that does not verify is often broken on purpose: the lab's task tells you when that is the case. With your machine ready and these commands at hand, you can start the first module.
