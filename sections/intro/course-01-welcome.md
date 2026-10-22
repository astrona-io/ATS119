# Welcome To The Course

This course trains you for the **Cosign Container & Blob Artifact Signing** part of the Astrona **Sigstore** training path. That part is 20% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes and `kubectl`, and you know what a container image, a tag and a registry are. You have seen a JSON document and can read it with `jq`. You do not need to know Sigstore or cryptography yet: each new idea is explained the first time it appears.

## What you can do at the end

Signing only helps if someone checks the signature, so this course does not stop at "sign". Every skill ends with a verification that passes, and often with a second one that fails for the right reason. The course has four topics.

The first topic is **signing container images**. You will learn to:

- Create a key pair with `cosign` and protect the private key with a password.
- Sign an image by its digest, add annotations, and verify the signature.
- Find the signature in the registry and tell which key made it.

The second topic is **signing files and software bills of materials (SBOMs)**. You will learn to:

- Sign any file with `cosign sign-blob` and keep the result in a Sigstore bundle.
- Generate an SBOM for an image with `syft`, and sign it.
- Prove that a changed file no longer verifies.

The third topic is **attestations and policies**. You will learn to:

- Attach in-toto attestations to an image: build provenance and vulnerability scan results.
- Verify an attestation by its type and read what it says.
- Write a Rego policy that accepts a release only when its attestations say the right thing.

The fourth topic is **managing signing keys**. You will learn to:

- Import an existing key and keep keys in a key management service (KMS).
- Sign with a key that lives in OpenBao's Transit engine, so the private key never touches a disk.
- Rotate a signing key without breaking the signatures your users already trust.

Everything is written for **cosign v3.1.4**.

## The words this course uses

The pages use Sigstore's and the container world's own terms, because those are the words you meet in the tools, their errors and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **key pair** is a private key that makes signatures and a public key that checks them. A **digest** is the SHA-256 hash that names one exact image; a tag can move to another image, a digest cannot. A **Sigstore bundle** is one JSON document that holds a signature and everything needed to check it. An **attestation** is a signed statement about an artifact, such as "this image was built by the release builder".

The commands you will use most often are these:

| Command | What it does |
| --- | --- |
| `cosign sign` / `cosign verify` | Signs an image / checks an image's signature |
| `cosign sign-blob` / `cosign verify-blob` | Signs any file into a bundle / checks a file against its bundle |
| `cosign attest` / `cosign verify-attestation` | Attaches a signed statement to an image / checks it and, with a policy, its content |
| `regctl image digest` | Prints the digest a tag points at |

## The example setup in your playground

Every playground and lab runs the same small setup. An OCI registry inside the cluster, `registry.localtest.me:5001`, holds two versions of the demo application `podinfo`: `6.15.0`, the current release, and `6.14.1`, the old one. You work in the **workstation**, a pod with `cosign`, `syft`, `regctl` and the other tools already installed. The last section adds **OpenBao**, a secrets server whose Transit engine keeps a signing key for you.

Nothing in this course goes to the public Sigstore services. The labs sign with a key and a signing configuration that lists no transparency log, so your practice signatures stay inside your cluster. The pages explain this choice where it matters. Many labs start with something broken on purpose; that is the material, not a fault in the course.

## How the course is laid out

The course has four sections. It starts with images, moves to files and SBOMs, then to signed statements about an image, and ends with the keys behind every signature.

| Section | What it covers |
| --- | --- |
| 010 | Signing And Verifying Container Images |
| 020 | Signing Blobs, Bundles And SBOMs |
| 030 | Attestations And Policies |
| 040 | Managing Signing Keys |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
