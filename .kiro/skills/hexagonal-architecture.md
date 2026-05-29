---
name: hexagonal-architecture
description: Enforces hexagonal architecture boundaries in this gem. Use when adding new code, reviewing changes, or deciding where to place new functionality.
---

# Hexagonal Architecture (Ports & Adapters)

## Overview

This gem uses hexagonal architecture to keep the formatting domain isolated from external dependencies. The core logic is pure Ruby with no ActiveRecord, no I18n, no framework coupling. Adapters handle all external interactions through well-defined port interfaces.

## When to Use

- Adding new functionality (where does it go?)
- Adding a new resolver type
- Reviewing code for architecture violations
- Deciding whether to add a dependency

**When NOT to use:** Changes to gemspec, CI, documentation, or test infrastructure.

## Architecture Map

```
┌─────────────────────────────────────────────────┐
│                  Public API                       │
│         PaperTrail::Human.format(version)        │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────┐
│              Core (Domain)                        │
│  lib/paper_trail/human/core/                     │
│                                                  │
│  Presenter        — orchestrates formatting      │
│  FieldFormatter   — formats individual fields    │
│  ChangeExtractor  — extracts changes from version│
│                                                  │
│  RULES:                                          │
│  • No require of activerecord                    │
│  • No require of external gems                   │
│  • Only depends on Ports interfaces              │
│  • Pure Ruby, testable without DB                │
└──────────┬───────────────────────┬──────────────┘
           │                       │
    ┌──────▼──────┐         ┌──────▼──────┐
    │    Ports     │         │    Ports     │
    │  resolver.rb │         │  (future)    │
    │              │         │              │
    │  Contract:   │         │              │
    │  #resolve(v) │         │              │
    └──────┬──────┘         └──────────────┘
           │
    ┌──────▼──────────────────────────────┐
    │           Adapters                    │
    │  lib/paper_trail/human/adapters/     │
    │                                      │
    │  Resolvers::Relation  — ActiveRecord │
    │  Resolvers::Enum      — class method │
    │  Resolvers::Boolean   — pure Ruby    │
    │  Resolvers::Custom    — lambda       │
    │                                      │
    │  RULES:                              │
    │  • Implements Ports::Resolver         │
    │  • May use ActiveRecord, I18n, etc.  │
    │  • Isolated — one adapter per file   │
    └─────────────────────────────────────┘
```

## Decision Guide: Where Does New Code Go?

```
Is it formatting logic (no external deps)?     → core/
Is it an interface contract?                    → ports/
Does it talk to ActiveRecord/external service? → adapters/
Is it configuration/DSL?                       → configuration.rb
Is it Rails integration?                       → railtie.rb
```

## Adding a New Resolver

Follow this exact sequence:

1. **Port** — Verify `Ports::Resolver` interface covers the need (usually no change needed)
2. **Adapter** — Create `lib/paper_trail/human/adapters/resolvers/new_type.rb`
3. **Register** — Add to `RESOLVER_MAP` in `core/field_formatter.rb`
4. **Require** — Add to `lib/paper_trail/human.rb`
5. **Test** — Unit spec in `spec/unit/adapters/resolvers/new_type_spec.rb`
6. **Integration** — Verify it works through the full pipeline

```ruby
# Template for new resolver
# frozen_string_literal: true

module PaperTrail
  module Human
    module Adapters
      module Resolvers
        class NewType
          include Ports::Resolver

          def initialize(**options)
            # Store options
          end

          def resolve(value)
            # Transform value → human-readable string
          end
        end
      end
    end
  end
end
```

## Principles

| Principle | Rule | Violation Example |
|---|---|---|
| Dependency Rule | Core never imports adapters | `require 'active_record'` in core/ |
| Port Interface | All resolvers implement `#resolve(value)` | Resolver with `#call` or `#transform` |
| Immutability | ModelConfig frozen after registration | Mutating config at runtime |
| Thread Safety | Mutex for writes, lock-free reads | Class-level mutable variables |
| Composition | No monkey-patching PaperTrail | Reopening `PaperTrail::Version` |

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "It's just one ActiveRecord call in core" | One call becomes ten. The boundary exists to keep core testable without DB. |
| "This resolver is too simple for a separate file" | Consistency matters more than saving one file. Every resolver gets its own file. |
| "I'll extract the port later" | Later never comes. Define the interface first, implement second. |
| "Thread-safety isn't needed for a gem" | Gems run in Rails apps with Puma. Thread-safety is mandatory. |

## Red Flags

- `require 'active_record'` anywhere in `core/`
- A resolver that doesn't `include Ports::Resolver`
- Core specs that need database setup
- Mutable state in Configuration after `#freeze`
- Direct constant reference to adapter classes in core (use string-based lookup)

## Verification

When reviewing architecture compliance:

- [ ] No external gem requires in `lib/paper_trail/human/core/`
- [ ] All resolvers include `Ports::Resolver`
- [ ] All resolvers implement `#resolve(value) → String`
- [ ] Core specs pass without ActiveRecord loaded
- [ ] ModelConfig is frozen after registration
- [ ] No class-level mutable state (@@vars, unfrozen class ivars)
