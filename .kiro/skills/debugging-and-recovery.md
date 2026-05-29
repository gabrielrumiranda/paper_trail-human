---
name: debugging-and-recovery
description: Systematic debugging for this gem. Use when specs fail, builds break, or behavior is unexpected.
---

# Debugging & Error Recovery

## Overview

Five-step triage: reproduce, localize, reduce, fix, guard. Don't guess — follow the evidence.

## When to Use

- Specs fail unexpectedly
- `bundle exec rubocop` reports offenses after changes
- A resolver returns wrong values
- Thread-safety issues appear
- Integration with PaperTrail breaks

## The Five Steps

```
1. REPRODUCE  →  2. LOCALIZE  →  3. REDUCE  →  4. FIX  →  5. GUARD
   Confirm it       Find where       Minimal        Smallest     Regression
   actually         it breaks        repro case     change       spec
   fails
```

### Step 1: REPRODUCE

```bash
# Run the specific failing spec
bundle exec rspec spec/unit/core/presenter_spec.rb:42

# Run with verbose output
bundle exec rspec --format documentation spec/path/to_spec.rb

# Run in order (detect order-dependent failures)
bundle exec rspec --order defined
```

If you can't reproduce it, you can't fix it. Stop and gather more information.

### Step 2: LOCALIZE

```bash
# Is it a specific layer?
bundle exec rspec spec/unit/core/          # Core only
bundle exec rspec spec/unit/adapters/      # Adapters only
bundle exec rspec spec/integration/        # Integration only

# Is it a specific resolver?
bundle exec rspec spec/unit/adapters/resolvers/relation_spec.rb
```

### Step 3: REDUCE

Write the smallest possible spec that demonstrates the failure:

```ruby
it 'fails when value is nil' do
  resolver = described_class.new(class_name: 'Company', attribute: :name)
  expect(resolver.resolve(nil)).to eq(nil)  # This is the minimal repro
end
```

### Step 4: FIX

Apply the smallest change that fixes the issue. Don't refactor while fixing.

### Step 5: GUARD

The fix spec becomes a permanent regression guard:

```ruby
# This spec was added to prevent regression of issue #XX
it 'handles nil values gracefully' do
  expect(resolver.resolve(nil)).to eq(nil)
end
```

## Common Issues in This Gem

| Symptom | Likely Cause | Check |
|---|---|---|
| `NoMethodError: humanize` | Missing `activesupport` require | `require 'active_support/core_ext/string/inflections'` |
| `NameError: uninitialized constant` | Missing require or wrong namespace | Check `lib/paper_trail/human.rb` requires |
| Thread-related failures | Mutable shared state | Look for `@@vars` or unfrozen class ivars |
| YAML parse errors | `BigDecimal` not required | Add `require 'bigdecimal'` |
| `frozen` errors | Mutating frozen ModelConfig | Config mutation must happen before `#freeze` |

## Red Flags

- Fixing without reproducing first
- Changing multiple things at once to "see what works"
- Fixing the spec instead of the code
- Ignoring intermittent failures (often thread-safety)
- Not adding a regression guard

## Verification

- [ ] Bug reproduced with a failing spec
- [ ] Root cause identified and documented
- [ ] Fix is minimal (no unrelated changes)
- [ ] Regression spec added
- [ ] Full suite passes: `bundle exec rspec`
- [ ] Linter passes: `bundle exec rubocop`
