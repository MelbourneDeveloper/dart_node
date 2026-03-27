---
name: submit-pr
description: Creates a pull request with a well-structured description after verifying CI passes. Use when the user asks to submit, create, or open a pull request.
disable-model-invocation: true
---

# Submit PR

Create a pull request for the current branch with a well-structured description.

## Steps

1. Run `make ci` — must pass completely before creating PR
2. Determine the PR title from `git diff main...HEAD`
3. Write PR body using the template in `.github/pull_request_template.md`
4. Fill in:
   - TLDR: one sentence
   - What Was Added: new files, features, deps
   - What Was Changed or Deleted: modified behaviour
   - How Do The Automated Tests Prove It Works: specific test names or output
   - Spec/Doc Changes: if any
   - Breaking Changes: yes/no + description
5. Use `gh pr create` with the filled template

## Rules

- Never create a PR if `make ci` fails
- PR description must be specific — no vague placeholders
- Only diff against `main` — ignore commit messages (per CLAUDE.md)
- Link to the relevant GitHub issue if one exists

## Success criteria

- `make ci` passed
- PR created with `gh pr create`
- PR URL returned to user
