# paper_trail-human

Transforms `PaperTrail::Version` into human-readable hashes for UI display (audit logs, timelines, history).

Resolves foreign keys to names, translates enums/constants, formats booleans, and accepts custom transformations via lambda.

## Installation

```ruby
gem "paper_trail-human"
```

## Usage

### Configuration

```ruby
PaperTrail::Human.configure do |config|
  # Resolve who made the change
  config.whodunnit_resolver = ->(id) { User.find_by(id: id)&.name }

  # Ignored fields (default: id, created_at, updated_at)
  config.ignored_fields = %w[id created_at updated_at]

  # Per-model configuration
  config.register "User" do |m|
    m.field :role, :enum, class_name: "UserRole", method: :label
    m.field :company_id, :relation, class_name: "Company", attribute: :name
    m.field :active, :boolean, true_label: "Active", false_label: "Inactive"
    m.field :score, :custom, resolve: ->(v) { "#{v} points" }
  end
end
```

### Format a single version

```ruby
PaperTrail::Human.format(version)
# => {
#   user: "John",
#   event: "update",
#   model: "User",
#   item_id: 1,
#   created_at: 2026-05-29 12:00:00,
#   fields: [
#     { field: "Name", previous_value: "John", value: "John Smith" },
#     { field: "Company", previous_value: "Acme", value: "Globex" },
#   ]
# }
```

### Format a collection

```ruby
PaperTrail::Human.format_collection(user.versions)
```

## Resolvers

| Type | Description | Options |
|------|-------------|---------|
| `:relation` | Resolves FK to an attribute of another model | `class_name:`, `attribute:` |
| `:enum` | Resolves value to a human label | `class_name:`, `method:` or `mapping:` |
| `:boolean` | Custom labels for true/false | `true_label:`, `false_label:` |
| `:custom` | Lambda for arbitrary transformation | `resolve:` |

## Architecture

Hexagonal (Ports & Adapters):

- **Core** — pure formatting logic, no external dependencies
- **Ports** — `Resolver` interface that every adapter implements
- **Adapters** — concrete implementations (Relation, Enum, Boolean, Custom)

## Requirements

- Ruby >= 2.7
- Rails >= 5.2
- PaperTrail >= 9.0

## Development

```bash
bundle install
bundle exec rspec          # tests
bundle exec rubocop        # linter
bundle exec rake           # all
```

## License

MIT
