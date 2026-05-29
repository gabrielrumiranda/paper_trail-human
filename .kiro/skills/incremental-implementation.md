---
name: incremental-implementation
description: Delivers changes in thin vertical slices. Use when implementing any feature or change that touches more than one file in this gem.
---

# Incremental Implementation

## Overview

Build in thin vertical slices — implement one piece, test it, verify it, then expand. Each increment leaves the gem in a working, testable state with all specs passing.

## When to Use

- Implementing any multi-file change
- Adding a new resolver type
- Modifying the core formatting pipeline
- Any change touching more than ~50 lines

**When NOT to use:** Single-file fixes, documentation, config changes.

## The Increment Cycle

```
┌──────────────────────────────────────┐
│                                      │
│  Implement ──→ Test ──→ Verify ──┐   │
│       ▲                          │   │
│       └───── Commit ◄────────────┘   │
│                                      │
│              ▼                        │
│         Next slice                    │
└──────────────────────────────────────┘
```

For each slice:
1. **Implement** the smallest complete piece
2. **Test** — `bundle exec rspec`
3. **Verify** — `bundle exec rubocop` + manual check
4. **Commit** — atomic, descriptive message
5. **Next slice**

## Slicing Strategy for This Gem

### Adding a New Resolver

```
Slice 1: Port interface + unit spec (RED → GREEN)
Slice 2: Adapter implementation + unit spec
Slice 3: Integration with FieldFormatter + integration spec
Slice 4: Configuration DSL support
Slice 5: Documentation
```

### Modifying Core Pipeline

```
Slice 1: Unit spec for new behavior (RED)
Slice 2: Minimal implementation (GREEN)
Slice 3: Edge cases + specs
Slice 4: Integration spec
Slice 5: Refactor if needed
```

## Rules

### Rule 0: Simplicity First

Before writing code, ask: "What is the simplest thing that could work?"

```
SIMPLICITY CHECK:
✗ Generic resolver factory with plugin system for 5 resolvers
✓ Simple case/when in FieldFormatter with explicit resolver map

✗ Abstract base class with 6 template methods
✓ Module with one required method (#resolve)

✗ Event system for configuration changes
✓ Mutex-protected hash assignment
```

### Rule 1: Scope Discipline

Touch ONLY what the task requires. Do NOT:
- "Clean up" adjacent code
- Refactor imports in files you're not modifying
- Add features not in the spec
- Modernize syntax in files you're only reading

```
NOTICED BUT NOT TOUCHING:
- lib/paper_trail/human/railtie.rb could use lazy loading (separate task)
- The YAML parsing could be more robust (separate task)
→ Want me to create tasks for these?
```

### Rule 2: Keep It Green

After each increment, the project MUST:
- `bundle exec rspec` — all pass
- `bundle exec rubocop` — no offenses
- No broken requires or missing constants

### Rule 3: One Thing at a Time

Each increment changes one logical thing:

**Bad:** One commit that adds a resolver, modifies the presenter, and updates the gemspec.
**Good:** Three separate commits.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll test it all at the end" | Bugs compound. A bug in Slice 1 makes Slices 2-5 wrong. |
| "It's faster to do it all at once" | It feels faster until something breaks and you can't find which of 200 lines caused it. |
| "These changes are too small to commit separately" | Small commits are free. Large commits hide bugs. |
| "Let me just quickly add this too" | Scope creep. Note it, don't fix it. |
| "This refactor is small enough to include" | Refactors mixed with features make both harder to review. |

## Red Flags

- More than 50 lines written without running `bundle exec rspec`
- Multiple unrelated changes in a single increment
- Specs broken between slices
- Touching files outside the task scope
- Building abstractions before the third use case demands it

## Verification

After each increment:

- [ ] The change does ONE thing completely
- [ ] `bundle exec rspec` — all pass
- [ ] `bundle exec rubocop` — no offenses
- [ ] The new functionality works as expected
- [ ] Change is committed with descriptive message
- [ ] No files outside task scope were modified
