# Changelog

## [0.3.0] - 2026-05-30

### Added
- `:date` resolver with configurable `strftime` format
- `:number` resolver with currency, percentage, and custom formatting
- `item_name` resolver for human-readable record identifiers
- Output formats: `as: :text`, `as: :markdown`, `as: :html` (XSS-safe)
- `PaperTrail::Human.timeline` for grouping versions by day/week/month/year
- `after_format` hook for post-processing results
- CONTRIBUTING.md with architecture guide

### Changed
- Minimum Ruby version raised to 3.1 (dropped 2.7, 3.0)
- Minimum Rails version raised to 6.1 (dropped 5.2, 6.0)
- Minimum PaperTrail version raised to 12.0
- CI matrix: Ruby 3.1–3.4 × Rails 6.1–8.0 × PaperTrail 12–15
- README rewritten as full English documentation

### Removed
- Support for Ruby < 3.1, Rails < 6.1, PaperTrail < 12

## [0.2.0] - 2026-05-30

### Added
- I18n integration for field names via `activerecord.attributes`
- I18n event label translation with locale files (en, pt-BR)
- Rails native enum support (`from_model:` option)
- `:text` resolver for long text truncation with diff stats
- `only:` and `except:` field filters
- Batch loading of relations (N+1 prevention)
- Event-specific fields (create omits previous_value, destroy omits value)
- Warning when `object_changes` column is missing

### Fixed
- `Psych::DisallowedClass` with YAML serializer (added ActiveSupport::TimeWithZone)
- Field names now remove `_id` suffix automatically

## [0.1.0] - 2026-05-29

### Added
- Initial release
- Core presenter with hexagonal architecture
- Resolvers: relation, enum, boolean, custom
- Configuration DSL with per-model field registration
- Thread-safe configuration
- Support for JSON, YAML, and jsonb object_changes
- Whodunnit resolver callback
- Configurable ignored fields
- RuboCop configuration (rubocop-rspec, rubocop-performance)
- CI with GitHub Actions matrix (Ruby 3.0-3.3 × Rails 6.1-8.0)
