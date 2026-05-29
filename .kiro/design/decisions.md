# ADR-001: Hexagonal Architecture

## Status
Accepted

## Context
A gem de formatação precisa resolver dados de múltiplas fontes externas (ActiveRecord para relations, classes Ruby para enums, lambdas para custom). O core de formatação não deve depender dessas fontes.

## Decision
Usar arquitetura hexagonal (Ports & Adapters):
- **Core** (`core/`) — lógica pura de formatação, sem dependências externas
- **Ports** (`ports/`) — interfaces que o core espera
- **Adapters** (`adapters/`) — implementações concretas

## Consequences
- Core testável sem banco de dados (specs rápidas)
- Novos resolvers adicionados sem modificar core (Open/Closed)
- Mais arquivos/diretórios que uma gem flat
- Precisa de disciplina para manter boundaries

---

# ADR-002: Thread-Safety via Frozen Configs

## Status
Accepted

## Context
Gems Ruby rodam em apps Rails com Puma (multi-threaded). A configuração é escrita uma vez (boot) e lida muitas vezes (requests).

## Decision
- `Mutex` protege escritas em `Configuration#register`
- `ModelConfig#freeze` após registro (imutável para leituras)
- Sem `@@class_variables` em nenhum lugar
- `Presenter` é stateless (recebe config, retorna hash)

## Consequences
- Leituras são lock-free (performance)
- Configuração não pode ser alterada após freeze
- Testes precisam de `reset_configuration!` no before

---

# ADR-003: String-Based Resolver Lookup

## Status
Accepted

## Context
O core (`FieldFormatter`) precisa instanciar resolvers, mas não pode importar adapters diretamente (violaria hexagonal).

## Decision
Usar `RESOLVER_MAP` com strings de classe e `Object.const_get` para resolver em runtime.

## Consequences
- Core não tem `require` de adapters
- Erro claro se resolver type não existe no map
- Ligeiramente menos type-safe que referência direta
- Permite adicionar resolvers sem modificar core (só o map)
