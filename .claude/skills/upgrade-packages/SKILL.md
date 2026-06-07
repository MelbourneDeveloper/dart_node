---
name: upgrade-packages
description: Upgrade all dependencies/packages to their latest versions for the detected language(s). Use when the user says "upgrade packages", "update dependencies", "bump versions", "update packages", or "upgrade deps".
argument-hint: "[--check-only] [--major] [package-name]"
---
<!-- agent-pmo:76596cb -->

# Upgrade Packages

Upgrade all project dependencies to their latest compatible (or latest major, if `--major`) versions.

## Arguments

- `--check-only` — List outdated packages without upgrading. Stop after Step 2.
- `--major` — Include major version bumps (breaking changes). Without this flag, stay within semver-compatible ranges.
- Any other argument is treated as a specific package name to upgrade (instead of all packages).

## Step 1 — Detect language and package manager

Inspect the repo root and subdirectories for manifest files. Identify ALL that apply:

| Manifest file | Language | Package manager |
|---|---|---|
| `Cargo.toml` | Rust | cargo |
| `package.json` | Node.js / TypeScript | npm / yarn / pnpm (check lockfile) |
| `pyproject.toml` | Python | pip / uv / poetry (check `[build-system]` or `[tool.poetry]`) |
| `requirements.txt` | Python | pip |
| `setup.py` / `setup.cfg` | Python | pip |
| `pubspec.yaml` | Dart / Flutter | pub |
| `*.csproj` / `*.fsproj` / `*.sln` | C# / F# | NuGet (dotnet) |
| `Directory.Build.props` | C# / F# | NuGet (dotnet) |
| `go.mod` | Go | go modules |
| `Gemfile` | Ruby | bundler |
| `composer.json` | PHP | composer |
| `build.gradle` / `build.gradle.kts` | Java / Kotlin | gradle |
| `pom.xml` | Java | maven |

If multiple languages are present, process each one in order.

**If you cannot detect any manifest file, stop and tell the user.**

## Step 2 — List outdated packages

Run the appropriate command to list what's outdated BEFORE upgrading anything. Show the user what will change.

### Rust
```bash
cargo outdated        # install: cargo install cargo-outdated
cargo update --dry-run
```
**Read the docs:** https://doc.rust-lang.org/cargo/commands/cargo-update.html

### Node.js (npm)
```bash
npm outdated
```
If using yarn: `yarn outdated`. If using pnpm: `pnpm outdated`.

**Read the docs:**
- npm: https://docs.npmjs.com/cli/v10/commands/npm-update
- yarn: https://yarnpkg.com/cli/up
- pnpm: https://pnpm.io/cli/update

### Python (pip)
```bash
pip list --outdated
```
If using uv: `uv pip list --outdated`. If using poetry: `poetry show --outdated`.

**Read the docs:**
- pip: https://pip.pypa.io/en/stable/cli/pip_install/#cmdoption-U
- uv: https://docs.astral.sh/uv/reference/cli/#uv-pip-install
- poetry: https://python-poetry.org/docs/cli/#update

### Dart / Flutter
```bash
dart pub outdated
# or for Flutter projects:
flutter pub outdated
```
**Read the docs:** https://dart.dev/tools/pub/cmd/pub-outdated

### C# / F# (NuGet)
```bash
dotnet list package --outdated
```
For transitive dependencies too: `dotnet list package --outdated --include-transitive`

**Read the docs:** https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-list-package

### Go
```bash
go list -m -u all
```
**Read the docs:** https://go.dev/ref/mod#go-get

### Ruby (Bundler)
```bash
bundle outdated
```
**Read the docs:** https://bundler.io/man/bundle-update.1.html

### PHP (Composer)
```bash
composer outdated
```
**Read the docs:** https://getcomposer.org/doc/03-cli.md#update-u-upgrade

### Java / Kotlin (Gradle)
```bash
./gradlew dependencyUpdates  # requires ben-manes/gradle-versions-plugin
```
**Read the docs:** https://docs.gradle.org/current/userguide/dependency_management.html

### Java (Maven)
```bash
mvn versions:display-dependency-updates
```
**Read the docs:** https://www.mojohaus.org/versions/versions-maven-plugin/display-dependency-updates-mojo.html

If `--check-only` was passed, **stop here** and report the outdated list.

## Step 3 — Read the official upgrade docs

**Before running any upgrade command, you MUST fetch and read the official documentation URL listed above for the detected package manager.** Use WebFetch to retrieve the page. This ensures you use the correct flags and understand the behavior. Do not guess at flags or options from memory.

## Step 4 — Upgrade packages

Run the upgrade. If a specific package name was given as an argument, upgrade only that package.

### Rust
```bash
cargo update                          # semver-compatible updates
# --major flag:
cargo update --breaking               # major version bumps (cargo 1.84+)
```
For workspace members, run from workspace root.

### Node.js (npm)
```bash
npm update                            # semver-compatible (within package.json ranges)
# --major flag:
npx npm-check-updates -u && npm install   # bump package.json to latest majors
```
If using yarn: `yarn up` / `yarn up -R '**'`. If using pnpm: `pnpm update` / `pnpm update --latest`.

### Python (pip)
For `requirements.txt`:
```bash
pip install --upgrade -r requirements.txt
pip freeze > requirements.txt         # pin new versions
```
For `pyproject.toml` with pip: update version specifiers manually, then `pip install -e ".[dev]"`.
For uv: `uv pip install --upgrade -r requirements.txt` or `uv lock --upgrade`.
For poetry: `poetry update` / `poetry update --latest` (with `--major` flag).

### Dart / Flutter
```bash
dart pub upgrade                      # semver-compatible
# --major flag:
dart pub upgrade --major-versions     # bump to latest majors
```
For Flutter: replace `dart` with `flutter`.

### C# / F# (NuGet)
There is NO single `dotnet upgrade-all` command. You must upgrade each package individually:
```bash
# For each outdated package from Step 2:
dotnet add <project.csproj> package <PackageName>    # upgrades to latest
# Or with specific version:
dotnet add <project.csproj> package <PackageName> --version <version>
```
For `Directory.Build.props`, edit the version numbers directly in the XML.

**Read the docs:** https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-add-package

Alternatively, use the dotnet-outdated global tool:
```bash
dotnet tool install --global dotnet-outdated-tool
dotnet outdated --upgrade
```
**Read the docs:** https://github.com/dotnet-outdated/dotnet-outdated

### Go
```bash
go get -u ./...                       # update all dependencies
go mod tidy                           # clean up go.sum
```
For a specific package: `go get -u <module>@latest`.

### Ruby (Bundler)
```bash
bundle update                         # all gems
# specific gem:
bundle update <gem-name>
```

### PHP (Composer)
```bash
composer update                       # all packages
# specific package:
composer update <vendor/package>
```
With `--major`: edit `composer.json` version constraints first, then `composer update`.

### Java / Kotlin (Gradle)
Edit version numbers in `build.gradle` / `build.gradle.kts` / version catalogs (`libs.versions.toml`), then:
```bash
./gradlew dependencies                # verify resolution
```

### Java (Maven)
```bash
mvn versions:use-latest-releases      # update pom.xml to latest releases
mvn versions:commit                   # remove backup pom
```

## Step 5 — Verify the upgrade

After upgrading, run the project's build and test suite to confirm nothing broke:

```bash
make ci
```

If `make ci` is not available, run whatever build/test commands the project uses (check the Makefile, CI workflow, or CLAUDE.md).

If tests fail:
1. Read the failure output carefully
2. Check the changelog / migration guide for the upgraded packages (fetch the release notes URL if available)
3. Fix breaking changes in the code
4. Re-run tests
5. If stuck after 3 attempts on the same failure, report it to the user with the error details and the package that caused it

## Step 6 — Report

Provide a summary:

- Packages upgraded (old version -> new version)
- Packages skipped (and why, e.g., major version bump without `--major` flag)
- Build/test result after upgrade
- Any breaking changes that were fixed
- Any packages that could not be upgraded (with error details)

## Rules

- **Always list outdated packages first** before upgrading anything
- **Always read the official docs** for the package manager before running upgrade commands
- **Always run tests after upgrading** to catch breakage immediately
- **Never remove packages** unless they were explicitly deprecated and replaced
- **Never downgrade packages** unless rolling back a broken upgrade
- **Never modify lockfiles manually** (package-lock.json, yarn.lock, Cargo.lock, etc.) — let the package manager regenerate them
- **Commit nothing** — leave changes in the working tree for the user to review

## Success criteria

- All outdated packages upgraded to latest compatible (or latest major if `--major`)
- Build passes
- Tests pass
- User has a clear summary of what changed
