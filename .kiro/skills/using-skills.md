---
name: using-skills
description: Discovers and invokes the right skill for the current task. Use when starting a session or deciding which skill applies.
---

# Using Skills

## Overview

This meta-skill helps discover and apply the right workflow for the current task in the paper_trail-human gem.

## Skill Discovery

```
Task arrives
│
├── Implementing new feature?        → incremental-implementation + tdd-ruby
├── Adding a new resolver?           → hexagonal-architecture + tdd-ruby
├── Fixing a bug?                    → debugging-and-recovery + tdd-ruby
├── Reviewing code?                  → code-review
├── Architecture question?           → hexagonal-architecture
├── Specs failing?                   → debugging-and-recovery
├── Refactoring?                     → tdd-ruby (ensure specs pass before AND after)
└── Shipping a release?              → code-review (self-review) + verification
```

## Core Operating Behaviors

These apply at ALL times, across all skills:

### 1. Surface Assumptions

Before implementing anything non-trivial:

```
ASSUMPTIONS:
1. [assumption about requirements]
2. [assumption about architecture layer]
3. [assumption about scope]
→ Correct me now or I'll proceed with these.
```

### 2. Enforce Simplicity

Before finishing any implementation, ask:
- Can this be done in fewer lines?
- Are these abstractions earning their complexity?
- Would a senior Rubyist say "why didn't you just..."?

### 3. Scope Discipline

Touch ONLY what you're asked to touch. Do NOT:
- Remove comments you don't understand
- "Clean up" adjacent code
- Add features not in the spec
- Refactor while fixing a bug

### 4. Verify, Don't Assume

Every task ends with verification:
```bash
bundle exec rspec        # All specs pass
bundle exec rubocop      # No offenses
```

"Seems right" is NEVER sufficient.

## Typical Sequences

**New resolver:**
`hexagonal-architecture` → `tdd-ruby` → `incremental-implementation` → `code-review`

**Bug fix:**
`debugging-and-recovery` → `tdd-ruby` → `code-review`

**Refactoring:**
`tdd-ruby` (verify green) → implement → `tdd-ruby` (verify still green) → `code-review`

## Failure Modes to Avoid

1. Writing code without a failing spec first
2. Violating hexagonal boundaries "just this once"
3. Skipping verification because "it looks right"
4. Scope creep — fixing unrelated things
5. Over-engineering for hypothetical future needs
6. Not running rubocop before considering done
