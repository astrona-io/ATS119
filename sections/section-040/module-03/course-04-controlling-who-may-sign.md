# Controlling Who May Sign

A KMS moves the security question from "who has the file?" to "who may ask for a signature?". The answer lives in the access rules of the service. This part describes the rules that matter for signing keys and the habits that keep a KMS key safe, and checks that no private key file is left behind.

## What cosign needs from OpenBao

To sign, cosign needs permission to use the sign endpoint of the key and to read the key's public part. For OpenBao, an access policy lists paths and capabilities. A policy for one signing key has two rules:

```hcl
path "transit/sign/demo-a" {
  capabilities = ["update"]
}

path "transit/keys/demo-a" {
  capabilities = ["read"]
}
```

A token with this policy can sign with `demo-a` and read its public key. It cannot read other keys, create keys or delete them. This is an example to read, not a command to run in the lab, where the root token is in use.

## Separate who signs from who administers

The pipeline that signs releases needs the policy above. A person who creates, rotates or deletes keys needs more, and should be a different identity. If one token can do both, a compromised pipeline can delete or replace the key. Give each identity the minimum it needs.

## Tokens are the new key files

The token that allows signing is as sensitive as a key file with its password. It should be short lived, issued to the pipeline and not stored in the repository. The development token `root` in the lab is the opposite of this advice, and shows why development mode must not run outside a lab.

## Check for leftovers

When a team moves from key files to a KMS, old key files often stay behind in folders and backups. List the key folder and make sure it holds only public keys:

<!-- astrona:playground:renew -->

```sh
ls /work/keys
ls /work/keys/*.key 2>/dev/null || echo "no private key files"
```

The folder holds `demo-a.pub` and `demo-b.pub`, and no `.key` file. A leftover `.key` file can still sign, even after the team switched to the KMS.

You now know how a KMS key is created, exported, audited and controlled. The graded lab asks you to export two public keys, find out which key signed which release, and write a report without creating any private key file.


## Common pitfalls

> [!WARNING]
> - **Using the root token for pipelines.** Give a pipeline a policy that allows signing with one key.
> - **Leaving old key files after a migration.** They keep their signing power.
> - **Letting the signing identity manage keys.** Separate signing from administration.

## Your mission: Find Out Which KMS Key Signed Which Release

You can now export KMS public keys and use verification to find the signer of a release. The graded lab gives you two Transit keys and two signed releases. You export the public keys and write a report of which key signed which release.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-119-playground-040-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS119.git -c sections/section-040/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-119-lab-040-03
astrona start ats-119-playground-040-03
```
