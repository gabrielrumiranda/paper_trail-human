# Arquitetura — paper_trail-human

## Visão Geral

A gem `paper_trail-human` transforma `PaperTrail::Version` em hashes legíveis para exibição em UIs de auditoria. Utiliza **arquitetura hexagonal (Ports & Adapters)** para manter o domínio de formatação isolado de dependências externas.

```
┌─────────────────────────────────────────────────────────────────┐
│                         Public API                                │
│                                                                  │
│   PaperTrail::Human.format(version)                              │
│   PaperTrail::Human.format_collection(versions)                  │
│   PaperTrail::Human.configure { |c| ... }                        │
│                                                                  │
└──────────────────────────────┬──────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│                        CORE (Domain)                             │
│                  lib/paper_trail/human/core/                      │
│                                                                  │
│  ┌─────────────┐  ┌────────────────┐  ┌──────────────────┐      │
│  │  Presenter  │  │ FieldFormatter │  │ ChangeExtractor  │      │
│  │             │  │                │  │                  │      │
│  │ Orquestra   │  │ Formata campo  │  │ Extrai changes   │      │
│  │ formatação  │──│ individual     │  │ de Version       │      │
│  │ completa    │  │ usando resolver│  │ (JSON/YAML/Hash) │      │
│  └─────────────┘  └───────┬────────┘  └──────────────────┘      │
│                            │                                     │
│  REGRAS:                   │                                     │
│  • Zero dependências       │                                     │
│    externas                │                                     │
│  • Pure Ruby              │                                     │
│  • Testável sem banco     │                                     │
└────────────────────────────┼─────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│                         PORTS (Interfaces)                        │
│                   lib/paper_trail/human/ports/                    │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  module Ports::Resolver                                   │    │
│  │    def resolve(value) → String                            │    │
│  │  end                                                      │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                  │
│  Contrato que todo adapter deve implementar.                     │
│  O core depende APENAS desta interface.                          │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│                       ADAPTERS (Implementações)                   │
│              lib/paper_trail/human/adapters/resolvers/            │
│                                                                  │
│  ┌────────────┐ ┌────────┐ ┌─────────┐ ┌────────┐              │
│  │  Relation  │ │  Enum  │ │ Boolean │ │ Custom │              │
│  │            │ │        │ │         │ │        │              │
│  │ FK → nome  │ │ valor  │ │ true →  │ │ lambda │              │
│  │ via AR     │ │ → label│ │ label   │ │ livre  │              │
│  └────────────┘ └────────┘ └─────────┘ └────────┘              │
│                                                                  │
│  REGRAS:                                                         │
│  • Implementam include Ports::Resolver                           │
│  • Podem usar ActiveRecord, I18n, etc.                           │
│  • Isolados — um adapter por arquivo                             │
│  • Tratam NameError gracefully (fallback para valor raw)         │
└──────────────────────────────────────────────────────────────────┘
```

---

## Componentes

### Core

| Classe | Responsabilidade |
|--------|-----------------|
| `Presenter` | Orquestra a formatação completa de um `Version`. Recebe configuração, extrai changes, aplica formatação por campo, retorna hash estruturado. |
| `FieldFormatter` | Formata um campo individual. Resolve o nome humano do campo e aplica o resolver configurado (ou retorna valor raw). |
| `ChangeExtractor` | Extrai o hash de mudanças de um `Version`. Suporta `object_changes` em JSON, YAML e Hash (jsonb). Infere changes de `object` para create/destroy. |

### Ports

| Interface | Contrato |
|-----------|----------|
| `Ports::Resolver` | `#resolve(value) → String` — transforma um valor raw em representação legível. |

### Adapters

| Adapter | Input | Output | Dependência |
|---------|-------|--------|-------------|
| `Relation` | FK (Integer) | Nome do registro | ActiveRecord (`find_by`) |
| `Enum` | Valor do enum | Label humano | Classe Ruby com método ou mapping hash |
| `Boolean` | `true`/`false` | Label customizado | Nenhuma |
| `Custom` | Qualquer valor | Resultado do lambda | Nenhuma |

### Configuration

| Componente | Responsabilidade |
|------------|-----------------|
| `Configuration` | DSL de configuração. Thread-safe (Mutex para writes, frozen para reads). Registra configs por model. |
| `ModelConfig` | Armazena campos configurados para um model. Frozen após registro. |

---

## Fluxo de Dados

```
PaperTrail::Version
        │
        ▼
┌─────────────────┐
│ ChangeExtractor │──→ { "name" => ["Old", "New"], "company_id" => [1, 2] }
└─────────────────┘
        │
        ▼
┌─────────────────┐
│    Presenter    │──→ Filtra ignored_fields, resolve whodunnit
└─────────────────┘
        │
        ▼ (para cada campo)
┌─────────────────┐
│ FieldFormatter  │──→ Busca config do campo → instancia resolver → resolve valores
└─────────────────┘
        │
        ▼
{
  user: "João Silva",
  event: "update",
  model: "User",
  item_id: 1,
  created_at: 2026-05-29 12:00:00,
  fields: [
    { field: "Nome", previous_value: "João", value: "João Silva" },
    { field: "Empresa", previous_value: "Acme", value: "Globex" }
  ]
}
```

---

## Thread-Safety

| Mecanismo | Onde | Por quê |
|-----------|------|---------|
| `Mutex` (double-check locking) | `PaperTrail::Human.configuration` | Inicialização lazy thread-safe |
| `Mutex#synchronize` | `Configuration#register` | Escrita concorrente no hash de configs |
| `ModelConfig#freeze` | Após registro | Leituras lock-free (imutável) |
| Stateless `Presenter` | Cada `format` call | Sem estado compartilhado entre requests |

---

## Decisões de Design (ADRs)

### ADR-001: Hexagonal Architecture

**Contexto:** O domínio precisa resolver dados de múltiplas fontes externas.
**Decisão:** Core sem dependências externas. Adapters implementam ports.
**Consequência:** Core testável sem banco. Novos resolvers sem modificar core.

### ADR-002: Thread-Safety via Frozen Configs

**Contexto:** Gems rodam em apps Rails com Puma (multi-threaded).
**Decisão:** Mutex para writes, frozen configs para reads.
**Consequência:** Leituras lock-free. Config imutável após boot.

### ADR-003: String-Based Resolver Lookup

**Contexto:** Core não pode importar adapters diretamente.
**Decisão:** `RESOLVER_MAP` com strings + `Object.const_get` em runtime.
**Consequência:** Core sem requires de adapters. Erro claro para types inválidos.

### ADR-004: Graceful Fallback

**Contexto:** Models podem ser deletados, classes renomeadas.
**Decisão:** Resolvers capturam `NameError` e retornam valor raw.
**Consequência:** Logs de auditoria nunca explodem. Dados degradam gracefully.

---

## Estrutura de Diretórios

```
lib/paper_trail/human/
├── core/                          # Domain — lógica pura
│   ├── presenter.rb               # Orquestra formatação
│   ├── field_formatter.rb         # Formata campo individual
│   └── change_extractor.rb        # Extrai changes (JSON/YAML/Hash)
├── ports/                         # Interfaces
│   └── resolver.rb                # Contrato: #resolve(value)
├── adapters/                      # Implementações concretas
│   └── resolvers/
│       ├── relation.rb            # FK → nome via ActiveRecord
│       ├── enum.rb                # Valor → label
│       ├── boolean.rb             # Bool → label customizado
│       └── custom.rb              # Lambda livre
├── configuration.rb               # DSL thread-safe
├── railtie.rb                     # Integração Rails (opcional)
└── version.rb                     # Versão da gem

spec/
├── unit/                          # Testes isolados (doubles, sem DB)
│   ├── core/
│   │   ├── presenter_spec.rb
│   │   ├── field_formatter_spec.rb
│   │   └── change_extractor_spec.rb
│   ├── adapters/resolvers/
│   │   ├── relation_spec.rb
│   │   ├── enum_spec.rb
│   │   ├── boolean_spec.rb
│   │   └── custom_spec.rb
│   └── configuration_spec.rb
└── integration/                   # Testes end-to-end
    ├── format_spec.rb
    └── thread_safety_spec.rb
```

---

## Como Estender

### Adicionar novo resolver

1. Criar `lib/paper_trail/human/adapters/resolvers/novo_tipo.rb`
2. Implementar `include Ports::Resolver` + `#resolve(value)`
3. Adicionar ao `RESOLVER_MAP` em `core/field_formatter.rb`
4. Adicionar `require_relative` em `lib/paper_trail/human.rb`
5. Criar spec em `spec/unit/adapters/resolvers/novo_tipo_spec.rb`

### Customizar nomes de campos

```ruby
PaperTrail::Human.configure do |config|
  config.field_name_resolver = ->(field_name, item_type) {
    item_type.constantize.human_attribute_name(field_name)
  }
end
```

### Adicionar campos ignorados

```ruby
PaperTrail::Human.configure do |config|
  config.ignored_fields = %w[id created_at updated_at encrypted_password]
end
```
