# paper_trail-human — Project Spec

## What It Does

Transforms `PaperTrail::Version` into human-readable hashes for audit log UIs.

## Architecture

Hexagonal (Ports & Adapters). See `.kiro/skills/hexagonal-architecture.md`.

## Requirements

### Functional
1. Format a single `PaperTrail::Version` into structured hash
2. Format a collection of versions
3. Resolve whodunnit via configurable callback
4. Support 4 resolver types: relation, enum, boolean, custom
5. Per-model field configuration via DSL
6. Ignore configurable fields (default: id, created_at, updated_at)
7. Fallback to `human_attribute_name` for unconfigured fields

### Technical
- Ruby >= 3.0, Rails >= 6.1, PaperTrail >= 12.0
- Zero deps beyond activerecord, activesupport, paper_trail
- Thread-safe (Mutex for writes, frozen configs)
- No monkey-patching — composition only
- Support object_changes in JSON, YAML, and jsonb

## API

```ruby
PaperTrail::Human.format(version)
# => { user:, event:, model:, item_id:, created_at:, fields: [...] }

PaperTrail::Human.format_collection(versions)

PaperTrail::Human.configure do |config|
  config.whodunnit_resolver = ->(id) { User.find_by(id: id)&.name }
  config.ignored_fields = %w[id created_at updated_at]
  config.register 'User' do |m|
    m.field :role, :enum, class_name: 'UserRole', method: :label
    m.field :company_id, :relation, class_name: 'Company', attribute: :name
    m.field :active, :boolean, true_label: 'Ativo', false_label: 'Inativo'
    m.field :score, :custom, resolve: ->(v) { "#{v} pontos" }
  end
end
```

## Tasks

- [x] Task 1: Gem structure, gemspec, CI, linters
- [x] Task 2: Core — Presenter, FieldFormatter, ChangeExtractor
- [x] Task 3: Adapters — Relation, Enum, Boolean, Custom resolvers
- [x] Task 4: Configuration DSL (thread-safe)
- [ ] Task 5: Railtie + integration tests with real ActiveRecord
- [ ] Task 6: Batch loading for relations (N+1 prevention)
- [ ] Task 7: I18n support for event labels
- [ ] Task 8: Publish to RubyGems

## Verification

```bash
bundle exec rspec        # 34 specs, 0 failures
bundle exec rubocop      # 0 offenses
```
