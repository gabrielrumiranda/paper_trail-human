---
name: tdd-ruby
description: Drives development with Red-Green-Refactor cycle for Ruby/RSpec. Use when implementing any logic, fixing any bug, or changing any behavior in this gem.
---

# Test-Driven Development (Ruby)

## Overview

Write a failing spec before writing the code that makes it pass. For bug fixes, reproduce the bug with a spec before attempting a fix. Tests are proof — "seems right" is not done.

## When to Use

- Implementing any new logic or behavior
- Fixing any bug (the Prove-It Pattern)
- Modifying existing functionality
- Adding a new resolver or adapter

**When NOT to use:** Pure configuration changes (gemspec, CI), documentation updates, or renaming without behavior change.

## The TDD Cycle

```
RED                    GREEN                  REFACTOR
Write a spec     →    Write minimal code  →  Clean up the
that fails            to make it pass         implementation  → (repeat)
│                     │                       │
▼                     ▼                       ▼
Spec FAILS            Spec PASSES             Specs still PASS
```

### Step 1: RED — Write a Failing Spec

```ruby
# spec/unit/core/presenter_spec.rb
RSpec.describe PaperTrail::Human::Core::Presenter do
  it 'formats a version with resolved fields' do
    # This fails because the feature doesn't exist yet
    result = presenter.call(version)
    expect(result[:fields].first[:value]).to eq('Resolved Name')
  end
end
```

Run: `bundle exec rspec spec/unit/core/presenter_spec.rb`
It MUST fail. A spec that passes immediately proves nothing.

### Step 2: GREEN — Make It Pass

Write the MINIMUM code to make the spec pass. Don't over-engineer.

```ruby
# Minimal implementation — no optimization, no generalization
def call(version)
  { fields: [{ value: resolve(version) }] }
end
```

Run: `bundle exec rspec spec/unit/core/presenter_spec.rb`
It MUST pass.

### Step 3: REFACTOR — Clean Up

With specs green, improve without changing behavior:
- Extract shared logic
- Improve naming
- Remove duplication

Run: `bundle exec rspec && bundle exec rubocop`
Both MUST pass.

## The Prove-It Pattern (Bug Fixes)

```
Bug report arrives
│
▼
Write a spec that demonstrates the bug
│
▼
Spec FAILS (confirming the bug exists)
│
▼
Implement the fix
│
▼
Spec PASSES (proving the fix works)
│
▼
Run full suite (no regressions)
```

## Test Pyramid for This Gem

```
         ╱╲
        ╱  ╲         Integration (~20%)
       ╱    ╲        End-to-end format, thread-safety
      ╱──────╲
     ╱        ╲      Unit (~80%)
    ╱          ╲     Core logic, each resolver isolated
   ╱────────────╲
```

### Where Tests Live

| Type | Path | Uses | Speed |
|------|------|------|-------|
| Unit (core) | `spec/unit/core/` | Doubles, no DB | ms |
| Unit (adapters) | `spec/unit/adapters/` | Stubs, stub_const | ms |
| Unit (config) | `spec/unit/` | Pure Ruby | ms |
| Integration | `spec/integration/` | Full flow, threads | ms-s |

### Decision Guide

```
Is it pure formatting logic?           → Unit spec in spec/unit/core/
Is it a resolver in isolation?         → Unit spec in spec/unit/adapters/
Does it test the full format pipeline? → Integration spec
Does it test thread-safety?            → Integration spec
```

## Writing Good Specs

### Test State, Not Interactions

```ruby
# Good: Tests what the resolver does
expect(resolver.resolve(42)).to eq('Company Name')

# Bad: Tests how it works internally
expect(Company).to have_received(:find_by).with(id: 42)
```

### DAMP Over DRY

Each spec should be self-contained and readable:

```ruby
# Good: Each spec tells a complete story
it 'resolves true to custom label' do
  resolver = described_class.new(true_label: 'Ativo', false_label: 'Inativo')
  expect(resolver.resolve(true)).to eq('Ativo')
end

it 'resolves false to custom label' do
  resolver = described_class.new(true_label: 'Ativo', false_label: 'Inativo')
  expect(resolver.resolve(false)).to eq('Inativo')
end
```

### Prefer Real Implementations Over Mocks

```
Preference order:
1. Real implementation (stub_const with real class behavior)
2. Struct doubles (Struct.new(:name).new('Value'))
3. instance_double with allow
4. Mock (verify method calls) — use sparingly
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll add specs later" | Later never comes. The spec IS the design step. Write it first. |
| "This is too simple to test" | Simple code gets complex. The spec documents expected behavior. |
| "I'll test it all at the end" | Bugs compound. A bug in the extractor makes the presenter wrong. Test each layer. |
| "The spec is obvious from the code" | Code shows WHAT. Specs show WHY and guard against regressions. |
| "Mocking everything is fine" | Over-mocking creates specs that pass while production breaks. Use real behavior. |
| "I need to refactor first" | RED first. Refactor comes AFTER green, not before red. |

## Red Flags

- Code written without a failing spec first
- Specs that test implementation details (method calls) instead of behavior
- Specs that pass on first run (didn't start with RED)
- `allow(...).to receive(...)` on more than 2 collaborators in one spec
- Specs that require database setup for core logic
- Full suite taking > 5 seconds

## Verification

After completing TDD cycle:

- [ ] Spec was written BEFORE implementation (RED first)
- [ ] Spec failed for the RIGHT reason (not syntax error)
- [ ] Implementation is MINIMAL (no premature optimization)
- [ ] `bundle exec rspec` — all pass
- [ ] `bundle exec rubocop` — no offenses
- [ ] No specs depend on test execution order
- [ ] Core specs use no ActiveRecord (doubles only)
