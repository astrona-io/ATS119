# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS119 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Cosign Container & Blob Artifact Signing** domain
  of the **Sigstore** training path (`ATP023`). It is 20% of the path. There is
  no official Sigstore certification exam; the path's domains and weights are
  Astrona's own, set in `ATP023/path.yaml`.
- **What the domain really tests:** signing and verifying with `cosign` and a
  key pair: sign an image by digest with annotations, sign files and SBOMs with
  bundles, attach in-toto attestations and check them with a policy, and manage
  keys (passwords, imports, KMS keys, rotation). Keyless signing is the next
  course; every graded lab here is key-based. Every fix is proved with a
  `cosign verify`, `verify-blob` or `verify-attestation` that passes, and
  usually with a second one that fails for the right reason.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | Signing And Verifying Container Images | image-signing |
  | 020 | Signing Blobs, Bundles And SBOMs | blob-signing |
  | 030 | Attestations And Policies | attestations |
  | 040 | Managing Signing Keys | key-management |

- **The versions:** `cosign` **v3.1.4**, `syft` **v1.55.0**, `regctl` 0.11.7,
  OpenBao **2.7.1** (development mode, section 040 only), on a single-node
  `kind` cluster. Do not teach flags or output from other versions without
  saying so; cosign v2 tutorials on the web show v2 behaviour.
- **The main sources:** <https://docs.sigstore.dev/>, the generated CLI pages
  in `doc/` of `sigstore/cosign` at tag `v3.1.4`, and the cosign source at that
  tag. Sigstore is an Open Source Security Foundation (OpenSSF) project; it is
  not a CNCF project.

### Status: built, not yet run

The first version of this repository was written from the Sigstore
documentation and the cosign v3.1.4 source **without a live run**. No
playground or lab has been started, and no `astrona test` has passed yet.
Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

Ranked risks to check first:

1. **Offline signing with an empty signing configuration.** Every environment
   ships `/setup/offline-signing-config.json`: a v0.2 signing configuration
   with empty `caUrls`, `oidcUrls`, `rekorTlogUrls` and `tsaUrls`, written by
   hand (the same file `cosign signing-config create --out <file>` makes with
   no service flags; ATS118 uses that command). From the
   v3.1.4 source: `ShouldUploadToTlog` returns false when the configuration
   lists no Rekor URL, and `signingConfigHasServices` is false, so cosign does
   not fetch the TUF trusted root while signing. Not yet seen: that `sign`,
   `sign-blob` and `attest` accept a configuration with empty lists and skip
   the timestamp authority without an error.
2. **What `cosign verify-attestation` prints.** Graders take `.payload` from
   each output line, base64-decode it and read the in-toto statement. Check
   that the v3 bundle-format output still has a top-level `payload`.
3. **`cosign clean --type all` on bundle-format referrers.** v3 signatures
   and attestations are referrers, so `--type signature` or `--type
   attestation` may not remove them; the course always uses `--type all` (or
   `referrer`). The capstone of section 030 removes the stale attestations of
   a digest with it, then attests again. Check that it removes exactly the
   referrers of that one digest.
4. **The OpenBao Transit provider.** cosign v3.1.4 uses
   `sigstore/sigstore/pkg/signature/kms/hashivault` v1.11.1, which registers
   both `hashivault://` and `openbao://` and reads `VAULT_ADDR`/`BAO_ADDR`,
   `VAULT_TOKEN`/`BAO_TOKEN` and `TRANSIT_SECRET_ENGINE_PATH` (default
   `transit`). Not yet seen against OpenBao 2.7.1.
5. **syft and a plain-HTTP registry.** The workstation sets
   `SYFT_REGISTRY_INSECURE_USE_HTTP=true`; check that `syft scan
   registry:<ref>` uses it.

### cosign v3.1.4 facts the text must respect

All of these come from `doc/` and `cmd/cosign/cli/options/` at `v3.1.4`:

- **The bundle format is the default** (`--new-bundle-format` defaults to
  true and is deprecated, because it will be the only format). Signatures and
  attestations are Sigstore bundles stored as OCI referrers of the image.
  `--registry-referrers-mode` takes `legacy` or `oci-1-1`.
- **A signing configuration is always used** (`--use-signing-config` defaults
  to true): without `--signing-config`, cosign takes the public-good
  configuration from TUF and uploads to the public Rekor and timestamp
  authority. **`--tlog-upload=false` is rejected while a signing configuration
  is in use**; the error tells the user to pass a signing configuration
  without a transparency log. Pages teach `--signing-config
  /setup/offline-signing-config.json` and say why.
- **Verifying a signature that is in no log** needs `--insecure-ignore-tlog`.
  The flag text says the artifact "cannot be publicly verified". Pages say
  this every time and never use it where a log entry is the point.
- **HTTP registry:** `--allow-http-registry` on `sign`, `verify`, `attest`,
  `verify-attestation`, `tree`, `download` and `clean`.
- **`generate-key-pair`** writes an encrypted `cosign.key` and `cosign.pub`
  (prefix with `--output-key-prefix`), asks for a password or reads
  `COSIGN_PASSWORD`, and has no algorithm flag (the key is ECDSA P-256).
  `--kms <uri>` creates the key in a KMS. `import-key-pair --key <pem>` imports
  an RSA or EC PEM key; `public-key --key <ref> --outfile <file>` exports a
  public key.
- **`sign-blob`** has `--bundle`, `--signing-config` and
  `--signing-algorithm`; `verify-blob` takes `--bundle` and `--key`.
- **`attest --type`** accepts `slsaprovenance`, `slsaprovenance02`,
  `slsaprovenance1`, `link`, `spdx`, `spdxjson`, `cyclonedx`, `vuln`,
  `openvex`, `custom` or a URI. `vuln` maps to
  `https://cosign.sigstore.dev/attestation/vuln/v1`, `custom` to
  `https://cosign.sigstore.dev/attestation/v1`, `openvex` to
  `https://openvex.dev/ns`. The `vuln` predicate is
  `{invocation, scanner{uri, version, db{uri, version}, result}, metadata{scanStartedOn, scanFinishedOn}}`.
- **`verify-attestation --policy`** takes `.cue` or `.rego` files. Rego is
  evaluated with the query `data.signature.allow`, Rego **v0** syntax
  (`allow { ... }`, no `if`), and `input` is the in-toto statement. **Every
  attestation of the requested type must pass**: one stale attestation that
  fails the policy makes the whole verification fail.
- **Deprecated in v3:** `cosign attach` and `cosign triangulate` still exist
  in v3.1.4 but are deprecated ("will be removed in v4.0.0"); they are left out
  of the generated `doc/` pages. Their messages point to `oras` for attaching
  artifacts and to `oras discover` or `cosign tree` for listing referrers.
  `cosign clean --type` takes `signature|attestation|referrer|sbom|all`
  (`sbom` is deprecated).
- **KMS references:** `awskms://`, `gcpkms://`, `azurekms://`,
  `hashivault://` (and `openbao://`), `k8s://`, `gitlab://`, `github://` (key
  generation), `env://`, `pkcs11:`.

### Terms, not metaphors

| Term | First-use definition (example wording) |
| --- | --- |
| Key pair | A private key that signs and a public key that verifies; cosign stores the private key encrypted with a password |
| Digest | The SHA-256 hash that names one exact image manifest; a tag can move, a digest cannot |
| Annotation | A key=value pair cosign puts in the signed payload, checked again with `verify -a` |
| Signed payload | The JSON cosign signs for an image: `critical.identity.docker-reference`, `critical.image.docker-manifest-digest`, `critical.type`, and optional annotations |
| OCI referrer | An artifact in the registry whose `subject` field points at another manifest; cosign v3 stores bundles this way |
| Sigstore bundle | One JSON document with the signature, the key hint or certificate, and any log or timestamp evidence |
| Signing configuration | The JSON file that tells cosign which Fulcio, Rekor and timestamp services to use when signing |
| SBOM | Software bill of materials: the list of packages inside an artifact, here in SPDX JSON |
| In-toto statement | A signed claim with a `subject` (the artifact digests), a `predicateType` and a `predicate` |
| Attestation | An in-toto statement signed and attached to an artifact |
| SLSA provenance | A predicate that records how and by which builder an artifact was built |
| KMS | A key management service that keeps the private key and signs on request; the key never leaves it |

### The example workloads

| Name | What it is |
| --- | --- |
| `registry` (namespace `registry`) | `registry:3.1.2`, plain HTTP on `registry.localtest.me:5001` inside the cluster. Lab-only |
| `workstation` (namespace `workstation`) | `alpine:3.22` with `cosign`, `rekor-cli`, `gitsign`, `regctl`, `syft`, `git`, `curl`, `jq`, `openssl`; working directory `/work` (an `emptyDir`) |
| `inventory/podinfo:6.15.0`, `:6.14.1` | Copied from `ghcr.io/stefanprodan/podinfo` (`linux/amd64` only) at start; 6.15.0 is the current release, 6.14.1 the old one |
| `/setup/offline-signing-config.json` | The signing configuration with no services, mounted from a ConfigMap |
| `/work/keys/` | Key pairs made by the seed or the reader; password `lab-only-password` |
| OpenBao (namespace `kms`, section 040) | `quay.io/openbao/openbao:2.7.1` in development mode at `http://openbao.kms:8200`, root token `root`, Transit at `transit/`. Lab-only |

Pages work in a shell in the workstation:
`kubectl -n workstation exec -it deploy/workstation -- sh`, then
`export COSIGN_PASSWORD=lab-only-password`, `REPO=$REGISTRY/inventory/podinfo`
and `SC=/setup/offline-signing-config.json`.

### Environment facts the text must respect

- **No key material in the repository.** Keys are generated in the
  environment by the seed or by the reader.
- **Nothing goes to the public-good instance** in a graded lab. Pages may
  mention it and show the public-good command as prose.
- **CoreDNS:** the `rewrite stop` block with the answer name rewritten back,
  copied from ATS118; never the one-line `rewrite name` form.
- **Graders use their own copy of the public key**, stored at seed time in a
  ConfigMap `lab-baseline-<key>` in the namespace `workstation`, so a reader
  cannot pass a check by replacing `/work/keys/*.pub`.

### Where things are in this repo

The layout is the same as every Astrona course: `astrona.yaml`, `README.md`,
`sections/intro/`, `sections/section-0N0/README.md`, module pages
(`course.md`, `course-0N-*.md`), `playground/` (`config.yaml`,
`bootstrap/prepare.sh`, `manifests/lab-start.yaml`, `docs/overview.md`),
labs (`config.yaml`, `README.md`, `prerequisites.md`, `question.md`,
`solution.md`, `bootstrap/01-install-tools.sh`, `bootstrap/02-seed-state.sh`,
`manifests/`, `solution/apply.sh`, `testing/wait-for-workstation.sh`,
`validation/validate-*.sh`) and one capstone per section.

**Generated files.** Everything in an environment except `docs/overview.md`,
`question.md` and `solution.md` was generated from one Python generator kept
outside the repository (`config.yaml`, author `README.md`,
`prerequisites.md`, the manifests and every script). The scripts share one
block of helpers (`ws`, `ws_sh`, `baseline`, `verify_key`, `sign_with`,
`make_key`). When you change a shared piece, change it in every environment.

### Lab metadata in `astrona.yaml`

`training:` block: id `ATS119`, domain `Cosign Container & Blob Artifact
Signing`, weight `20`. Lab entries carry `title`, `path`, `difficulty`,
`estimated_duration`, `topic`, `task_kind`, `tags`, `learning_goals`,
`resources`, in that order, as in ATS016.

- `topic`: exactly one of `image-signing`, `blob-signing`, `attestations`,
  `policies`, `key-management`.
- `task_kind`: `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8, only from this list: `cosign`, `key-pair`, `cosign-sign`,
  `cosign-verify`, `digest`, `annotations`, `oci-referrers`, `cosign-tree`,
  `signing-config`, `offline-signing`, `sign-blob`, `verify-blob`, `bundle`,
  `sbom`, `spdx`, `syft`, `checksums`, `cosign-attest`, `verify-attestation`,
  `in-toto`, `slsa-provenance`, `vuln-attestation`, `rego-policy`,
  `cosign-clean`, `key-rotation`, `import-key-pair`, `kms`, `openbao-transit`,
  `signed-payload`.
- `resources`: 1 to 4 pages on `docs.sigstore.dev`, `slsa.dev`,
  `in-toto.io`, `spdx.dev`, `openbao.org` or `github.com/sigstore/cosign`.
  The only place outside links are allowed.

### Running things

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-010/module-01/playground
astrona destroy ats-119-playground-010-01
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-119-lab-010-01
astrona test -c sections/section-010/module-01/labs/lab-01   # authors
```

Names: `ats-119-playground-<section>-<module>`, `ats-119-lab-<section>-<module>`,
`ats-119-capstone-<section>`. Graders check **behaviour** and reject the
plausible but wrong fix (signing with a new key instead of the published one,
signing a tag that points at the wrong digest, changing a signed file to make
it match, removing the attestations of an old release to make a policy pass,
keeping a private key on disk after moving to a KMS). A lab's `question.md`
and `solution.md` must match what its `validation/` scripts check.

### Where to find trusted sources

- **Cosign:** <https://docs.sigstore.dev/cosign/signing/overview/>,
  <https://docs.sigstore.dev/cosign/verifying/verify/>,
  <https://docs.sigstore.dev/cosign/key_management/overview/>,
  <https://docs.sigstore.dev/cosign/verifying/attestation/>,
  <https://docs.sigstore.dev/about/bundle/>
- **CLI reference:** `doc/cosign_*.md` in `sigstore/cosign` at `v3.1.4`
- **Formats:** <https://slsa.dev/spec/v1.0/provenance>,
  <https://github.com/in-toto/attestation>, <https://spdx.dev/>
- **KMS:** <https://docs.sigstore.dev/cosign/key_management/overview/>,
  <https://openbao.org/docs/secrets/transit/>
