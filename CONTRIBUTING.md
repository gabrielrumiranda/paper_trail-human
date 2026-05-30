# Contributing to paper_trail-human

Thank you for considering contributing! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Running Tests](#running-tests)
- [Architecture Overview](#architecture-overview)
- [Adding a New Resolver](#adding-a-new-resolver)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Release Process](#release-process)

## Code of Conduct

Be kind, respectful, and constructive. We're all here to build something useful.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/paper_trail-human.git`
3. Create a feature branch: `git checkout -b feat/my-feature`
4. Make your changes
5. Push and open a Pull Request

## Development Setup

```bash
# Install dependencies
bundle install

# Run the full suite
bundle exec rake

# Run tests only
bundle exec rspec

# Run linter only
bundle exec rubocop
```

### Testing against different Rails/PaperTrail versions

```bash
BUNDLE_GEMFILE=gemfiles/rails_6.1.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/rails_6.1.gemfile bundle exec rspec
```

Available gemfiles:

| Gemfile | Rails | PaperTrail |
|---------|-------|-----------|
| `gemfiles/rails_6.1.gemfile` | 6.1 | ~> 12.0 |
| `gemfiles/rails_7.0.gemfile` | 7.0 | ~> 13.0 |
| `gemfiles/rails_7.1.gemfile` | 7.1 | ~> 14.0 |
| `gemfiles/rails_7.2.gemfile` | 7.2 | ~> 15.0 |
| `gemfiles/rails_8.0.gemfile` | 8.0 | ~> 15.0 |

## Running Tests

```bash
# All tests
bundle exec rspec

# Specific file
bundle exec rspec spec/unit/adapters/resolvers/enum_spec.rb

# With documentation format
bundle exec rspec --format documentation

# With coverage report
COVERAGE=true bundle exec rspec
# Open coverage/index.html
```

## Architecture Overview

The gem follows a **Hexagonal Architecture** (Ports & Adapters):

```
lib/paper_trail/human/
├── core/                    # Pure business logic
│   ├── change_extractor.rb  # Parses object_changes (JSON/YAML/Hash)
│   ├── field_formatter.rb   # Dispatches to resolvers, humanizes field names
│   ├── event_translator.rb  # Translates event labels via I18n
│   ├── presenter.rb         # Formats a single version
│   ├── batch_presenter.rb   # Formats collections with N+1 prevention
│   └── timeline.rb          # Groups versions by time period
├── ports/
│   └── resolver.rb          # Interface that all resolvers implement
├── adapters/
│   ├── resolvers/           # Value transformation adapters
│   │   ├── relation.rb
│   │   ├── enum.rb
│   │   ├── boolean.rb
│   │   ├── custom.rb
│   │   ├── text.rb
│   │   ├── date.rb
│   │   └── number.rb
│   └── formatters/          # Output format adapters
│       ├── text.rb
│       ├── markdown.rb
│       └── html.rb
├── configuration.rb         # DSL and thread-safe config
├── railtie.rb               # Optional Rails integration
└── version.rb
```

### Key principles

- **Core has no external dependencies** — it only depends on Ruby stdlib
- **Adapters are interchangeable** — each implements the `Ports::Resolver` interface
- **Thread-safe** — configuration uses mutexes, model configs are frozen after registration
- **Zero N+1** — `BatchPresenter` preloads all relation records in one query

## Adding a New Resolver

1. Create the adapter at `lib/paper_trail/human/adapters/resolvers/my_resolver.rb`:

```ruby
# frozen_string_literal: true

module PaperTrail
  module Human
    module Adapters
      module Resolvers
        class MyResolver
          include Ports::Resolver

          def initialize(**options)
            # store options
          end

          def resolve(value)
            # transform and return the value
          end
        end
      end
    end
  end
end
```

2. Register it in `FieldFormatter::RESOLVER_MAP`:

```ruby
RESOLVER_MAP = {
  # ...existing resolvers...
  my_resolver: 'PaperTrail::Human::Adapters::Resolvers::MyResolver'
}.freeze
```

3. Add the require in `lib/paper_trail/human.rb`

4. Write specs at `spec/unit/adapters/resolvers/my_resolver_spec.rb`

5. Document it in the README under section 3 (Resolvers)

## Pull Request Guidelines

- **One feature per PR** — keep changes focused and reviewable
- **Write tests** — new features need specs, bug fixes need regression tests
- **Follow existing style** — run `bundle exec rubocop` before pushing
- **Update documentation** — if you add/change public API, update the README
- **Descriptive commits** — use imperative mood: "Add X resolver", "Fix Y bug"

### Branch naming

- `feat/description` — new features
- `fix/description` — bug fixes
- `docs/description` — documentation only
- `chore/description` — maintenance, CI, dependencies

### PR template

```
## Summary

Brief description of what this PR does.

## Changes

- What was added/changed/removed

## Tests

How many specs, coverage impact.
```

## Release Process

1. Update `CHANGELOG.md`
2. Bump version in `lib/paper_trail/human/version.rb`
3. Commit: `git commit -m "Bump version to X.Y.Z"`
4. Tag: `git tag vX.Y.Z`
5. Push: `git push origin main --tags`
6. Publish: `gem push pkg/paper_trail-human-X.Y.Z.gem`

## Questions?

Open an issue on GitHub. We're happy to help!
