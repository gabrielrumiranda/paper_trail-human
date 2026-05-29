---
name: code-review
description: Reviews code across correctness, architecture, security, and Ruby best practices. Use before merging any change to this gem.
---

# Code Review

## Overview

Evaluate changes across five dimensions specific to this Ruby gem: correctness, architecture compliance, Ruby idioms, thread-safety, and test quality.

## When to Use

- Before merging any change
- After implementing a feature (self-review)
- When reviewing a PR

## Review Framework

### 1. Correctness

- Does the code do what the spec says?
- Are edge cases handled (nil values, missing records, empty strings)?
- Do the specs actually verify the behavior?
- Are there race conditions in configuration access?

### 2. Architecture Compliance

- Does the change respect hexagonal boundaries?
- Core has no external dependencies?
- New resolvers implement `Ports::Resolver`?
- Dependencies flow inward (adapters → ports ← core)?

### 3. Ruby Idioms & Style

- Frozen string literals on every file?
- RuboCop passes with zero offenses?
- Naming follows Ruby conventions (snake_case, predicate methods with `?`)?
- No unnecessary metaprogramming?
- Prefer composition over inheritance?

### 4. Thread-Safety

- No mutable class-level state (`@@vars`, unfrozen class ivars)?
- Configuration writes protected by Mutex?
- Frozen objects where possible?
- No lazy initialization without synchronization?

### 5. Test Quality

- Unit specs use doubles (no DB)?
- Integration specs test full pipeline?
- Specs test behavior, not implementation?
- Edge cases covered (nil, empty, missing)?
- DAMP over DRY in specs?

## Output Format

```markdown
## Review Summary

**Verdict:** APPROVE | REQUEST CHANGES

### Critical (must fix)
- [File:line] Description and fix

### Important (should fix)
- [File:line] Description and fix

### Suggestions (consider)
- [File:line] Description

### What's Done Well
- Positive observation

### Verification
- [ ] Specs pass: `bundle exec rspec`
- [ ] Linter passes: `bundle exec rubocop`
- [ ] Architecture boundaries respected
- [ ] Thread-safety maintained
```

## Severity Guide

| Severity | Criteria | Examples |
|---|---|---|
| **Critical** | Breaks functionality, violates architecture, thread-unsafe | ActiveRecord in core/, mutable class state, broken resolver |
| **Important** | Missing test, poor error handling, wrong abstraction | Untested edge case, swallowed exception, leaky abstraction |
| **Suggestion** | Style, naming, optional optimization | Better variable name, extract method, simplify conditional |

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "It's just one small violation" | Architecture erosion starts with one violation. Hold the line. |
| "The tests pass so it's fine" | Tests verify behavior, not design. Architecture review is separate. |
| "It's internal, nobody will see it" | Internal code becomes public API. Write it right the first time. |
| "I'll fix it in the next PR" | Tech debt compounds. Fix it now or create a tracked issue. |

## Red Flags

- `require 'active_record'` in `core/` files
- Resolver without `include Ports::Resolver`
- Specs that test method calls instead of outcomes
- `@@class_variable` anywhere
- Missing `# frozen_string_literal: true`
- Specs that depend on execution order
- Swallowed exceptions (`rescue => e; end`)

## Verification

Review is complete when:

- [ ] All Critical issues resolved
- [ ] All Important issues resolved or tracked
- [ ] `bundle exec rspec` passes
- [ ] `bundle exec rubocop` passes
- [ ] At least one positive observation noted
