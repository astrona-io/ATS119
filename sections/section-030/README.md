# Section 030: Attestations And Policies

A signature says "this key holder approved this image". It does not say how the image was built or what a scanner found in it. An **attestation** does: it is a signed statement about an image, attached to it like a signature. This section attaches build provenance and vulnerability scan results to the release, verifies them, and writes policies that accept a release only when its attestations say the right thing.

## What you will learn

- The in-toto statement: subject, predicate type and predicate.
- The predicate types cosign knows, such as SLSA provenance and vulnerability scans.
- Attaching attestations with `cosign attest` and checking them with `cosign verify-attestation`.
- Reading the statement inside an attestation.
- Writing a Rego policy that `cosign verify-attestation --policy` evaluates, and why every attestation of a type must pass it.

## The learning path

The section has one module, with a landing page, three short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground.

### 1. Attach Attestations To Images

The playground holds the registry with the `podinfo` images, the workstation, and two example predicates in `/work/predicates`.

1. In-Toto Statements And Predicate Types
2. Attesting Provenance And Scan Results, followed by the lab **Attach Provenance And Vulnerability Attestations**
3. Checking Attestations With A Policy
4. Summary

## Section capstone: Gate A Release On Its Attestations

The release 6.15.0 carries a stale scan with two critical findings and provenance from the developer builder. A fresh scan and the release provenance exist as files. You write the release policies and make the release pass them, while the old release keeps failing. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-119-capstone-030
```
