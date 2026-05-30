# Roadmap — paper_trail-human

## v0.3.1 — Bug Fixes

### 1. N+1 queries on `item_name` in `format_collection`

**Problem:** Each version triggers an individual `find_by` to resolve `item_name`. In a collection of 100 versions of the same model, this means 100 extra queries.

**Solution:** Batch-load item records in `BatchPresenter`, similar to how relations are preloaded. Group versions by `item_type`, collect all `item_id`s, load them in one query, and pass the cache to `resolve_item_name`.

**Impact:** Critical for production use with `format_collection` and `timeline`.

---

### 2. `Number` resolver generates leading space when `unit` is nil

**Problem:** `format_currency` does `"#{@unit} #{number}"` — when `unit` is nil, output is `" 1,500.99"` with a leading space.

**Solution:**

```ruby
def format_currency(num)
  @unit ? "#{@unit} #{format_number(num)}" : format_number(num)
end
```

---

### 3. `format_collection` with `as:` has no separator between entries

**Problem:** When using `format_collection(versions, as: :text)`, all entries are concatenated without any separator. Output is unreadable.

**Solution:** Join entries with `"\n\n"` for text/markdown, and concatenate divs for HTML.

---

## v0.4.0 — Extensibility

### 4. Custom resolver registration

**Problem:** Adding a new resolver type requires editing `FieldFormatter::RESOLVER_MAP` in the gem's core. Third-party code cannot extend the gem without forking.

**Solution:**

```ruby
PaperTrail::Human.configure do |config|
  config.register_resolver :money, MyMoneyResolver
end
```

The resolver class must include `PaperTrail::Human::Ports::Resolver` and implement `#resolve(value)`.

---

### 5. Custom formatter registration

**Problem:** Same as above but for output formatters. Only `:text`, `:markdown`, and `:html` are available. Users cannot add `:json`, `:slack`, etc.

**Solution:**

```ruby
PaperTrail::Human.configure do |config|
  config.register_formatter :json, MyJsonFormatter
end
```

The formatter class must implement `#call(result)` and return a string.

---

### 6. Lazy loading with `autoload`

**Problem:** All 7 resolvers and 3 formatters are loaded on boot via `require_relative`, even if the app only uses 2 of them.

**Solution:** Replace `require_relative` with `autoload` for adapters. Core modules remain eagerly loaded.

```ruby
module Adapters
  module Resolvers
    autoload :Date, 'paper_trail/human/adapters/resolvers/date'
    autoload :Number, 'paper_trail/human/adapters/resolvers/number'
  end
end
```

**Impact:** Faster boot time for apps that use few resolvers.

---

## v0.5.0 — Advanced Features

### 7. Diff mode for text fields

**Problem:** The `:text` resolver truncates, but doesn't show what actually changed. For long text fields (descriptions, bios), users want to see additions/removals.

**Solution:**

```ruby
m.field :body, :text, diff: true
# => { field: "Body", additions: 5, deletions: 2, summary: "+5/-2 lines" }
```

Use a simple line-based diff (no external dependency).

---

### 8. Batch `item_name` with custom preloader

**Problem:** Even with fix #1, `item_name` via lambda cannot be batched (it receives a single version).

**Solution:** Allow `item_name` to accept a batch-aware option:

```ruby
m.item_name :name, preload: true  # uses find_by on the model
m.item_name ->(version) { ... }   # still works, but no batching
```

---

### 9. Webhook/Event system

**Problem:** `after_format` is synchronous and single-purpose. Users may want to trigger side effects (send to Slack, log to external audit system).

**Solution:**

```ruby
config.on_format do |result, version|
  AuditLog.push(result) if result[:event] == "destroy"
end
```

Multiple callbacks, executed in order. Failures don't block the main return.

---

### 10. Association changes tracking

**Problem:** PaperTrail with `paper_trail-association_tracking` stores association changes, but `paper_trail-human` doesn't know how to format them.

**Solution:** Detect and format `has_many` changes:

```ruby
# => { field: "Tags", previous_value: ["ruby", "rails"], value: ["ruby", "rails", "gem"] }
```

---

## Prioritization

| # | Item | Type | Value | Effort | Release |
|---|------|------|-------|--------|---------|
| 1 | N+1 on item_name | Bug | Critical | Medium | v0.3.1 |
| 2 | Number unit nil | Bug | High | Low | v0.3.1 |
| 3 | Collection separator | Bug | Medium | Low | v0.3.1 |
| 4 | Custom resolver registration | Extensibility | High | Low | v0.4.0 |
| 5 | Custom formatter registration | Extensibility | High | Low | v0.4.0 |
| 6 | Lazy loading | Performance | Medium | Low | v0.4.0 |
| 7 | Text diff mode | Feature | Medium | Medium | v0.5.0 |
| 8 | Batch item_name | Performance | Medium | Medium | v0.5.0 |
| 9 | Event system | Extensibility | Low | Medium | v0.5.0 |
| 10 | Association changes | Feature | Medium | High | v0.5.0 |
