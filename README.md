# paper_trail-human

[![Gem Version](https://badge.fury.io/rb/paper_trail-human.svg)](https://rubygems.org/gems/paper_trail-human)
[![CI](https://github.com/gabrielrumiranda/paper_trail-human/actions/workflows/ci.yml/badge.svg)](https://github.com/gabrielrumiranda/paper_trail-human/actions)

Transforms `PaperTrail::Version` records into structured, human-readable hashes ready for UI display — audit logs, timelines, activity feeds.

Resolves foreign keys to names, translates enums and constants, formats dates and numbers, and accepts custom transformations via lambda.

## Table of Contents

- [1. Introduction](#1-introduction)
  - [1a. Compatibility](#1a-compatibility)
  - [1b. Installation](#1b-installation)
  - [1c. Quick Start](#1c-quick-start)
- [2. Configuration](#2-configuration)
  - [2a. Global Options](#2a-global-options)
  - [2b. Per-Model Fields](#2b-per-model-fields)
  - [2c. Item Name](#2c-item-name)
  - [2d. After Format Hook](#2d-after-format-hook)
- [3. Resolvers](#3-resolvers)
  - [3a. Relation](#3a-relation)
  - [3b. Enum](#3b-enum)
  - [3c. Boolean](#3c-boolean)
  - [3d. Custom](#3d-custom)
  - [3e. Text](#3e-text)
  - [3f. Date](#3f-date)
  - [3g. Number](#3g-number)
- [4. Formatting](#4-formatting)
  - [4a. Single Version](#4a-single-version)
  - [4b. Collection](#4b-collection)
  - [4c. Filtering Fields](#4c-filtering-fields)
  - [4d. Output Formats](#4d-output-formats)
- [5. Timeline](#5-timeline)
- [6. I18n](#6-i18n)
  - [6a. Field Names](#6a-field-names)
  - [6b. Event Labels](#6b-event-labels)
- [7. Architecture](#7-architecture)
- [8. Requirements](#8-requirements)
- [9. Contributing](#9-contributing)
- [10. License](#10-license)

## 1. Introduction

### 1a. Compatibility

| paper_trail-human | ruby    | activerecord | paper_trail |
|-------------------|---------|--------------|-------------|
| 0.3.x             | >= 3.1  | >= 6.1       | >= 12.0     |
| 0.2.x             | >= 3.0  | >= 6.1       | >= 12.0     |
| 0.1.x             | >= 2.7  | >= 5.2       | >= 9.0      |

**CI matrix (0.3.x):**

| Rails | PaperTrail | Ruby              |
|-------|-----------|-------------------|
| 6.1   | ~> 12.0   | 3.1, 3.2, 3.3, 3.4 |
| 7.0   | ~> 13.0   | 3.1, 3.2, 3.3, 3.4 |
| 7.1   | ~> 14.0   | 3.1, 3.2, 3.3, 3.4 |
| 7.2   | ~> 15.0   | 3.1, 3.2, 3.3, 3.4 |
| 8.0   | ~> 15.0   | 3.2, 3.3, 3.4      |

### 1b. Installation

Add to your Gemfile:

```ruby
gem "paper_trail-human"
```

Then run:

```bash
bundle install
rails generate paper_trail:human:install
```

The generator creates an initializer at `config/initializers/paper_trail_human.rb`.

**Important:** This gem reads from the `object_changes` column. If your versions table doesn't have it, add it:

```bash
rails generate paper_trail:install --with-changes
rails db:migrate
```

### 1c. Quick Start

```ruby
# config/initializers/paper_trail_human.rb
PaperTrail::Human.configure do |config|
  config.whodunnit_resolver = ->(id) { User.find_by(id: id)&.name }
end

# Anywhere in your app
PaperTrail::Human.format(version)
# => {
#   user: "John",
#   event: "update",
#   model: "User",
#   item_id: 1,
#   created_at: 2026-05-29 12:00:00,
#   fields: [
#     { field: "Name", previous_value: "John", value: "John Smith" },
#     { field: "Company", previous_value: "Acme", value: "Globex" }
#   ]
# }
```

## 2. Configuration

### 2a. Global Options

```ruby
PaperTrail::Human.configure do |config|
  # Resolve whodunnit IDs to names (default: nil, returns raw ID)
  config.whodunnit_resolver = ->(id) { User.find_by(id: id)&.name }

  # Fields to exclude from output (default: %w[id created_at updated_at])
  config.ignored_fields = %w[id created_at updated_at]

  # Custom field name resolver (default: nil, uses I18n then humanize)
  config.field_name_resolver = ->(field, model) { ... }

  # Translate event names via I18n (default: false)
  config.translate_events = true

  # Post-processing hook (default: nil)
  config.after_format = ->(result, version) { result }
end
```

### 2b. Per-Model Fields

```ruby
PaperTrail::Human.configure do |config|
  config.register "User" do |m|
    m.field :role, :enum, class_name: "UserRole", method: :label
    m.field :company_id, :relation, class_name: "Company", attribute: :name
    m.field :active, :boolean, true_label: "Active", false_label: "Inactive"
    m.field :bio, :text, max_length: 100, show_diff_stats: true
    m.field :due_date, :date, format: "%d/%m/%Y"
    m.field :salary, :number, format: :currency, unit: "R$"
    m.field :score, :custom, resolve: ->(v) { "#{v} points" }
  end
end
```

### 2c. Item Name

Adds a human-readable identifier for the record to the output:

```ruby
config.register "User" do |m|
  m.item_name :name
  # or with a lambda:
  m.item_name ->(version) { "User ##{version.item_id}" }
end

PaperTrail::Human.format(version)[:item_name]
# => "João Silva"
```

The `item_name` key is only present when the record exists and the attribute is configured.

### 2d. After Format Hook

Post-process every formatted result:

```ruby
config.after_format = ->(result, version) {
  result[:record_url] = "/#{result[:model].tableize}/#{result[:item_id]}"
  result
}
```

The lambda receives the formatted hash and the original `PaperTrail::Version`, and must return the hash.

## 3. Resolvers

### 3a. Relation

Resolves a foreign key to an attribute of the associated model.

```ruby
m.field :company_id, :relation, class_name: "Company", attribute: :name
```

| Option | Description | Default |
|--------|-------------|---------|
| `class_name:` | The associated model class | required |
| `attribute:` | Attribute to display | `:name` |

In batch mode (`format_collection`), relations are preloaded to prevent N+1 queries.

### 3b. Enum

Resolves enum values to human labels.

```ruby
# With a class that responds to a method
m.field :role, :enum, class_name: "UserRole", method: :label

# With a static mapping
m.field :status, :enum, mapping: { "active" => "Active", "inactive" => "Inactive" }

# With Rails native enum
m.field :role, :enum, from_model: "User"
m.field :role, :enum, from_model: "User", labels: { admin: "Administrator" }
```

| Option | Description |
|--------|-------------|
| `class_name:` + `method:` | Calls `ClassName.method(value)` |
| `mapping:` | Static hash lookup |
| `from_model:` | Reads from `Model.defined_enums` |
| `labels:` | Custom labels for `from_model` |

### 3c. Boolean

Custom labels for boolean fields:

```ruby
m.field :active, :boolean, true_label: "Active", false_label: "Inactive"
```

### 3d. Custom

Arbitrary transformation via lambda:

```ruby
m.field :score, :custom, resolve: ->(value) { "#{value} points" }
```

### 3e. Text

Truncates long text fields:

```ruby
m.field :body, :text, max_length: 100, show_diff_stats: true
# => "Lorem ipsum dolor sit amet..." (250 chars)
```

| Option | Description | Default |
|--------|-------------|---------|
| `max_length:` | Maximum characters before truncation | `80` |
| `show_diff_stats:` | Append total char count | `false` |

### 3f. Date

Formats date/time values:

```ruby
m.field :due_date, :date, format: "%d/%m/%Y"
# => "30/05/2026"
```

| Option | Description | Default |
|--------|-------------|---------|
| `format:` | `strftime` format string | `"%Y-%m-%d"` |

Accepts `Date`, `Time`, `DateTime`, and parseable strings.

### 3g. Number

Formats numeric values:

```ruby
m.field :amount, :number, format: :currency, unit: "R$"
# => "R$ 1,500.99"

m.field :rate, :number, format: :percentage
# => "85.50%"
```

| Option | Description | Default |
|--------|-------------|---------|
| `format:` | `:default`, `:currency`, `:percentage` | `:default` |
| `unit:` | Currency symbol (for `:currency`) | `nil` |
| `precision:` | Decimal places | `2` |
| `delimiter:` | Thousands separator | `","` |
| `separator:` | Decimal separator | `"."` |

## 4. Formatting

### 4a. Single Version

```ruby
PaperTrail::Human.format(version)
```

Returns a hash with keys: `user`, `event`, `model`, `item_id`, `created_at`, `fields`, and optionally `item_name`.

Event-specific behavior:
- **create**: fields omit `previous_value`
- **update**: fields include both `previous_value` and `value`
- **destroy**: fields omit `value`

### 4b. Collection

```ruby
PaperTrail::Human.format_collection(user.versions)
```

Same as `format` but for multiple versions. Relations are batch-loaded to prevent N+1 queries.

### 4c. Filtering Fields

```ruby
PaperTrail::Human.format(version, only: [:name, :email])
PaperTrail::Human.format(version, except: [:password_digest])
```

### 4d. Output Formats

By default, methods return hashes. Use `as:` for string output:

```ruby
PaperTrail::Human.format(version, as: :text)
# => "Updated User#1 by John at 2026-05-30\n  • Name: Old → New"

PaperTrail::Human.format(version, as: :markdown)
# => Markdown with header and table

PaperTrail::Human.format(version, as: :html)
# => HTML div with table (XSS-safe, escapes entities)
```

Available formats: `:text`, `:markdown`, `:html`.

Works with both `format` and `format_collection`.

## 5. Timeline

Group versions by time period:

```ruby
PaperTrail::Human.timeline(user.versions, group_by: :day)
# => {
#   "2026-05-28" => [{ user: ..., fields: [...] }, ...],
#   "2026-05-30" => [{ user: ..., fields: [...] }]
# }
```

| `group_by` | Format | Example |
|-----------|--------|---------|
| `:day` | `%Y-%m-%d` | `"2026-05-30"` |
| `:week` | `%G-W%V` | `"2026-W22"` |
| `:month` | `%Y-%m` | `"2026-05"` |
| `:year` | `%Y` | `"2026"` |

Supports `only:` and `except:` filters.

## 6. I18n

### 6a. Field Names

Field names are resolved in this order:

1. Custom `field_name_resolver` lambda (if configured)
2. `I18n.t("activerecord.attributes.model_name.field_name")` (if I18n available)
3. Automatic humanization (removes `_id` suffix, titleizes)

Example: `company_id` → looks up `activerecord.attributes.user.company_id` → falls back to `"Company"`.

### 6b. Event Labels

Enable translated event labels:

```ruby
config.translate_events = true
```

The gem includes locale files for `en` and `pt-BR`. Add your own:

```yaml
# config/locales/paper_trail_human.en.yml
en:
  paper_trail_human:
    events:
      create: "Created"
      update: "Updated"
      destroy: "Destroyed"
```

```yaml
# config/locales/paper_trail_human.pt-BR.yml
pt-BR:
  paper_trail_human:
    events:
      create: "Criação"
      update: "Atualização"
      destroy: "Exclusão"
```

## 7. Architecture

Hexagonal (Ports & Adapters):

```
┌─────────────────────────────────────────────┐
│                   Core                       │
│  ChangeExtractor · FieldFormatter            │
│  EventTranslator · Presenter                 │
│  BatchPresenter  · Timeline                  │
├─────────────────────────────────────────────┤
│                   Ports                       │
│  Resolver (interface)                        │
├─────────────────────────────────────────────┤
│                  Adapters                     │
│  Resolvers: Relation, Enum, Boolean,         │
│             Custom, Text, Date, Number       │
│  Formatters: Text, Markdown, Html            │
└─────────────────────────────────────────────┘
```

- **Core** — pure formatting logic, no external dependencies
- **Ports** — `Resolver` interface that every adapter implements
- **Adapters** — concrete implementations for resolving values and formatting output

The gem has zero dependencies beyond `activerecord` and `paper_trail`. The Railtie is optional — it works in non-Rails apps (Sinatra, Hanami, etc).

## 8. Requirements

- Ruby >= 3.1
- Rails >= 6.1 (or standalone ActiveRecord)
- PaperTrail >= 12.0

## 9. Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on setting up the development environment, running tests, and submitting pull requests.

## 10. License

MIT. See [LICENSE.txt](LICENSE.txt).
