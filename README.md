# paper_trail-human

Transforma `PaperTrail::Version` em hashes legíveis para exibição em UI (logs de auditoria, timelines, históricos).

Resolve foreign keys para nomes, traduz enums/constantes, formata booleans e aceita transformações customizadas via lambda.

## Instalação

```ruby
gem "paper_trail-human"
```

## Uso

### Configuração

```ruby
PaperTrail::Human.configure do |config|
  # Resolver quem fez a alteração
  config.whodunnit_resolver = ->(id) { User.find_by(id: id)&.name }

  # Campos ignorados (default: id, created_at, updated_at)
  config.ignored_fields = %w[id created_at updated_at]

  # Configuração por model
  config.register "User" do |m|
    m.field :role, :enum, class_name: "UserRole", method: :label
    m.field :company_id, :relation, class_name: "Company", attribute: :name
    m.field :active, :boolean, true_label: "Ativo", false_label: "Inativo"
    m.field :score, :custom, resolve: ->(v) { "#{v} pontos" }
  end
end
```

### Formatar uma version

```ruby
PaperTrail::Human.format(version)
# => {
#   user: "João",
#   event: "update",
#   model: "User",
#   item_id: 1,
#   created_at: 2026-05-29 12:00:00,
#   fields: [
#     { field: "Nome", previous_value: "João", value: "João Silva" },
#     { field: "Empresa", previous_value: "Acme", value: "Globex" },
#   ]
# }
```

### Formatar uma coleção

```ruby
PaperTrail::Human.format_collection(user.versions)
```

## Resolvers

| Tipo | Descrição | Opções |
|------|-----------|--------|
| `:relation` | Resolve FK para atributo de outro model | `class_name:`, `attribute:` |
| `:enum` | Resolve valor para label humano | `class_name:`, `method:` ou `mapping:` |
| `:boolean` | Labels customizados para true/false | `true_label:`, `false_label:` |
| `:custom` | Lambda para transformação arbitrária | `resolve:` |

## Arquitetura

Hexagonal (Ports & Adapters):

- **Core** — lógica pura de formatação, sem dependências externas
- **Ports** — interface `Resolver` que todo adapter implementa
- **Adapters** — implementações concretas (Relation, Enum, Boolean, Custom)

## Requisitos

- Ruby >= 3.0
- Rails >= 6.1
- PaperTrail >= 12.0

## Desenvolvimento

```bash
bundle install
bundle exec rspec          # testes
bundle exec rubocop        # linter
bundle exec rake           # tudo
```

## Licença

MIT
