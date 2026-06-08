---
name: release
description: Prepare and execute a release to pub.dev. Stamps placeholder versions from the tag in-runner (zero source churn), validates changelogs, checks pub.dev status, and guides through the tiered publishing process.
argument-hint: "<version>"
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, Glob, WebFetch
---

# Release to pub.dev

Prepare and execute a dart_node release. This is a multi-step process that publishes packages in tiers due to interdependencies.

## Version model — placeholders only ([SWR-VERSION-BUILD-STAMPING])

**Every `version:` in `packages/*/pubspec.yaml` is `0.0.0-dev` at all times, on every branch.** The real
version is stamped from the tag **in the CI runner's working tree only** at publish time and is **never
committed, pushed, branched, or PR'd back**. A release therefore produces **ZERO churn** on tracked source.

- Do NOT bump `version:` in source. Do NOT merge a "release" PR that changes a placeholder to a real version
  — there is no such PR anymore, and per the spec it must be rejected in review.
- Inter-package deps stay as local `path:` deps in source; `tools/prepare_publish.dart <version>` switches
  them to `^<version>` in-runner at publish time.
- The only things committed for a release are **CHANGELOG** entries (release notes) — never version fields.

## Arguments

`$ARGUMENTS` = version to release (e.g., `0.12.0-beta`, `1.0.0`)

If no version provided, show current versions and prompt for the target version.

## Step 1: Pre-flight checks

### 1.1 Verify clean state

```bash
git status
git branch --show-current
```

- Must be on `main` branch
- Working directory should be clean
- Every `packages/*/pubspec.yaml` `version:` must read `0.0.0-dev` (placeholder). If any shows a real
  version, that is churn — reset it to `0.0.0-dev` before tagging.

### 1.2 Check current versions

```bash
grep -h "^version:" packages/*/pubspec.yaml | head -20
```

### 1.3 Validate all packages have configs

```bash
dart run tools/prepare_publish.dart 2>&1 || true
```

This shows any packages missing from `tools/lib/packages.dart`.

## Step 2: Dependency switching is automatic (no action)

Internal deps stay as local `path:` deps in source. Each tier workflow runs
`dart run tools/prepare_publish.dart <version>` **in the runner working tree** before publishing, which
stamps `0.0.0-dev` → `<version>` and rewrites `path:` deps to `^<version>`. Nothing is committed — the
runner is discarded after publish. You do not switch deps by hand and there is no release branch.

## Step 3: Validate changelogs

Every publishable package must have a `## $ARGUMENTS` entry in its CHANGELOG.md.

**Publishable packages** (must have changelog entries):

| Tier | Package |
|------|---------|
| 1 | dart_logging |
| 1 | dart_node_core |
| 2 | reflux |
| 2 | dart_node_express |
| 2 | dart_node_ws |
| 2 | dart_node_better_sqlite3 |
| 2 | dart_node_sql_js |
| 2 | dart_node_mcp |
| 3 | dart_node_react |
| 3 | dart_node_react_native |

Check each changelog:

```bash
VERSION="$ARGUMENTS"
for pkg in dart_logging dart_node_core reflux dart_node_express dart_node_ws dart_node_better_sqlite3 dart_node_sql_js dart_node_mcp dart_node_react dart_node_react_native; do
  if grep -q "^## $VERSION" "packages/$pkg/CHANGELOG.md" 2>/dev/null; then
    echo "✅ $pkg"
  else
    echo "❌ $pkg - missing ## $VERSION entry"
  fi
done
```

If any are missing, **stop and update the changelogs** before proceeding.

## Step 4: Validate READMEs

Each package should have a README.md. Quick sanity check:

```bash
for pkg in dart_logging dart_node_core reflux dart_node_express dart_node_ws dart_node_better_sqlite3 dart_node_sql_js dart_node_mcp dart_node_react dart_node_react_native; do
  if [[ -f "packages/$pkg/README.md" ]]; then
    LINES=$(wc -l < "packages/$pkg/README.md")
    echo "✅ $pkg - $LINES lines"
  else
    echo "❌ $pkg - missing README.md"
  fi
done
```

## Step 5: Check pub.dev status

Verify which versions are currently published:

```bash
for pkg in dart_logging dart_node_core reflux dart_node_express dart_node_ws dart_node_better_sqlite3 dart_node_sql_js dart_node_mcp dart_node_react dart_node_react_native; do
  LATEST=$(curl -s "https://pub.dev/api/packages/$pkg" | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4)
  echo "$pkg: $LATEST"
done
```

## Step 6: Run tests

Before releasing, ensure all tests pass:

```bash
./tools/test.sh
```

Or run specific tiers:

```bash
./tools/test.sh --tier 1
./tools/test.sh --tier 2
./tools/test.sh --tier 3
```

## Step 7: Preview the stamp (optional, local dry run)

To see what the in-runner stamp will produce, run it locally then **discard the changes** (never commit):

```bash
dart run tools/prepare_publish.dart $ARGUMENTS
git restore packages   # throw the stamp away — source must stay 0.0.0-dev
```

It stamps `0.0.0-dev` → `$ARGUMENTS` and rewrites `path:` deps to `^$ARGUMENTS`. CI does exactly this in the
runner working tree at publish time.

## Step 8: Create release tag

The release is triggered by pushing a tag:

```bash
git tag "Release/$ARGUMENTS"
git push origin "Release/$ARGUMENTS"
```

This triggers the **publish-tier1** workflow which, in a single throwaway runner:
1. Validates the tag is on `main` and changelogs have `## $ARGUMENTS`
2. Stamps versions/deps in the working tree (NOT committed)
3. Publishes dart_logging and dart_node_core

No release branch, no commit, no PR — zero churn.

## Step 9: Tier 2 publishing

After tier 1 succeeds and packages are live on pub.dev (wait ~5 minutes for indexing):

```bash
git tag "Release-Tier2/$ARGUMENTS"
git push origin "Release-Tier2/$ARGUMENTS"
```

Publishes: reflux, dart_node_express, dart_node_ws, dart_node_better_sqlite3, dart_node_sql_js, dart_node_mcp

## Step 10: Tier 3 publishing

After tier 2 succeeds:

```bash
git tag "Release-Tier3/$ARGUMENTS"
git push origin "Release-Tier3/$ARGUMENTS"
```

Publishes: dart_node_react, dart_node_react_native

Each tier stamps in its own runner and publishes — nothing is committed, so there is no release branch to
merge and no dependency "switch back" step. The release is complete once tier 3's packages are live.

## Verification

After release, verify all packages are available:

```bash
VERSION="$ARGUMENTS"
for pkg in dart_logging dart_node_core reflux dart_node_express dart_node_ws dart_node_better_sqlite3 dart_node_sql_js dart_node_mcp dart_node_react dart_node_react_native; do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://pub.dev/api/packages/$pkg/versions/$VERSION")
  if [[ "$HTTP_CODE" == "200" ]]; then
    echo "✅ $pkg@$VERSION published"
  else
    echo "❌ $pkg@$VERSION not found (HTTP $HTTP_CODE)"
  fi
done
```

## Troubleshooting

### Package already published
If a package version already exists, the publish script skips it. This is safe.

### Dependency resolution fails
Tier 2/3 packages depend on tier 1. Wait for tier 1 to be fully indexed on pub.dev before starting tier 2.

### Changelog validation fails
Add the missing `## X.Y.Z` header to the package's CHANGELOG.md with release notes.

## Checklist summary

- [ ] On main branch, clean working directory
- [ ] Every `packages/*/pubspec.yaml` `version:` is `0.0.0-dev` (placeholder)
- [ ] Internal deps are local `path:` deps (CI switches them in-runner)
- [ ] All changelogs have `## $ARGUMENTS` entries
- [ ] All READMEs are present and up-to-date
- [ ] All tests pass
- [ ] `Release/$ARGUMENTS` tag pushed (triggers tier 1)
- [ ] Tier 1 complete, packages live on pub.dev
- [ ] `Release-Tier2/$ARGUMENTS` tag pushed
- [ ] Tier 2 complete, packages live on pub.dev
- [ ] `Release-Tier3/$ARGUMENTS` tag pushed
- [ ] Tier 3 complete, packages live on pub.dev
- [ ] Source unchanged — every `version:` still `0.0.0-dev`, no release branch/PR created
