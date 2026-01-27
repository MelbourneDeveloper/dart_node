---
name: create-pr
description: Create a pull request using the dart_node PR template
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, Glob
---

# Create Pull Request

Create a PR following the dart_node template and conventions.

## Steps

1. **Check state**:
   ```bash
   git status
   git diff main...HEAD
   git log main..HEAD --oneline
   ```

2. **Analyze all commits** from the branch (NOT just the latest — ALL commits since diverging from main). Use `git diff main` to understand the full scope.

3. **Draft PR using the template** from `.github/PULL_REQUEST_TEMPLATE.md`:

   ```
   ## TLDR;
   [One sentence summary]

   ## What Does This Do?
   [Clear description of the change]

   ## Brief Details?
   [Implementation details, design decisions]

   ## How Do The Tests Prove The Change Works?
   [Describe test coverage and what the tests verify]
   ```

4. **Create the PR**:
   ```bash
   gh pr create --title "Short title under 70 chars" --body "$(cat <<'EOF'
   ## TLDR;
   ...

   ## What Does This Do?
   ...

   ## Brief Details?
   ...

   ## How Do The Tests Prove The Change Works?
   ...
   EOF
   )"
   ```

## Rules

- Keep the title under 70 chars
- Keep documentation tight (per CLAUDE.md)
- Only diff against `main` — ignore commit messages
- Push to remote with `-u` flag if needed
- Return the PR URL when done
