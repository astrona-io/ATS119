# Custom Predicate Types

Not every fact fits a predefined type. A release team may want to record that a human reviewed a release, with the reviewer's name and a ticket number. cosign supports this: you pick a predicate type URI that you own and write the predicate as JSON. This part attaches such a review record and shows how to attach more than one type to one digest.

## Write the predicate

The predicate is a JSON file with the facts you want to record. Keep the field names stable, because policies will read them:

<!-- astrona:playground:renew -->

```sh
mkdir -p /work/predicates
cat > /work/predicates/review.json <<'EOF'
{"reviewer": "release-team", "result": "approved", "ticket": "INV-1042"}
EOF
```

## Pick a predicate type URI

The URI names the kind of fact and its version. It does not have to be a working web address, but it should be one you control, so that nobody else uses it for a different meaning. Include a version at the end so you can change the shape later: `https://inventory.example/attestations/review/v1`.

## Attach the record

```sh
export COSIGN_PASSWORD=lab-only-password
REPO=$REGISTRY/inventory/podinfo
SC=/setup/offline-signing-config.json
DIGEST=$(regctl image digest $REPO:6.15.0)
cosign attest -y --key /work/keys/release.key --signing-config $SC --allow-http-registry \
  --type https://inventory.example/attestations/review/v1 \
  --predicate /work/predicates/review.json $REPO@$DIGEST
```

`--type` takes the URI when no short name applies. cosign does not interpret the predicate. It signs the JSON as it is.

## Several types on one digest

The digest now has an SPDX attestation and a review attestation. Verify each by its type, and notice that each check sees only its own type:

```sh
for t in spdxjson https://inventory.example/attestations/review/v1; do
  echo "type: $t"
  cosign verify-attestation --key /work/keys/release.pub --insecure-ignore-tlog --allow-http-registry \
    --type $t $REPO@$DIGEST | jq -r '.payload' | base64 -d | jq -r '.predicateType'
done
```

Each loop turn prints the predicate type of its own attestation. A consumer that needs both an SBOM and a review runs both checks. A digest without the review fails the second check, and the release can be held back.

You can now attach facts of your own to an image and keep them apart by type. The last part reads attestations in scripts and lists the mistakes to avoid.


## Common pitfalls

> [!WARNING]
> - **Changing the meaning of a type without changing its URI.** Add a new version to the URI when the predicate changes shape.
> - **Putting a mutable fact in a predicate.** A signature cannot be edited, so a new fact needs a new attestation.
> - **Using `custom` for everything.** A specific URI lets a policy tell the facts apart.
