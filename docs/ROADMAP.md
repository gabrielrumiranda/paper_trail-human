# Roadmap — paper_trail-human

## Concluído ✓

### v0.1.0
- [x] Arquitetura hexagonal (Ports & Adapters)
- [x] 4 resolvers: relation, enum, boolean, custom
- [x] Configuration DSL thread-safe
- [x] Suporte JSON, YAML e jsonb
- [x] CI com GitHub Actions (Ruby 3.0-3.3 × Rails 6.1-8.0)
- [x] RuboCop (rubocop-rspec, rubocop-performance, rubocop-rake)
- [x] Batch loading de relations (N+1 prevention)
- [x] Generator `rails g paper_trail:human:install`
- [x] Event-specific fields (create omite previous_value, destroy omite value)

---

## Próximas Features

### 4. I18n para event labels

**Problema:** O campo `event` retorna strings cruas (`"create"`, `"update"`, `"destroy"`). Em UIs brasileiras, precisa ser "Criação", "Atualização", "Exclusão".

**Solução:** Incluir locale files na gem com traduções default e permitir override pela app.

**API:**
```ruby
result = PaperTrail::Human.format(version)
result[:event]
# => "Criação" (quando I18n.locale == :pt-BR)
# => "Created" (quando I18n.locale == :en)
```

**Configuração:**
```ruby
# Opt-in (default: false, retorna string crua)
config.translate_events = true
```

**Locale files incluídos na gem:**
```yaml
# config/locales/paper_trail_human.pt-BR.yml
pt-BR:
  paper_trail_human:
    events:
      create: "Criação"
      update: "Atualização"
      destroy: "Exclusão"
```

**Implementação:**
- Novo adapter `Adapters::EventTranslator` (não é resolver, é tradutor)
- Railtie carrega locale files automaticamente
- Fallback para string crua se I18n não disponível

**Specs:**
- Unit: EventTranslator com locale mockado
- Integration: format com translate_events habilitado

---

### 5. Diff mode para campos de texto longo

**Problema:** Campos como `description` ou `notes` com texto longo mostram o conteúdo inteiro no before/after. Em UIs, isso polui o log.

**Solução:** Resolver `:text` que detecta campos longos e retorna resumo da mudança.

**API:**
```ruby
config.register 'Article' do |m|
  m.field :body, :text, max_length: 100
end

# Output:
{ field: "Body", previous_value: "Lorem ipsum... (342 chars)", value: "Lorem ipsum dolor... (389 chars)" }
```

**Opções:**
```ruby
m.field :body, :text,
  max_length: 100,        # Trunca com "..." após N chars (default: 80)
  show_diff_stats: true   # Adiciona "(+47 chars)" ou "(-12 chars)"
```

**Implementação:**
- Novo adapter `Adapters::Resolvers::Text`
- Trunca valor se `> max_length`
- Opcionalmente mostra delta de tamanho

**Specs:**
- Texto curto: retorna sem truncar
- Texto longo: trunca com "..."
- Com diff_stats: mostra delta

---

### 6. Filtro por campos específicos

**Problema:** Nem toda view precisa mostrar todos os campos alterados. Um painel de "últimas atividades" pode querer só nome e email, não todos os 15 campos.

**Solução:** Opções `only:` e `except:` no `format`.

**API:**
```ruby
PaperTrail::Human.format(version, only: [:name, :email])
# => Retorna apenas fields para name e email

PaperTrail::Human.format(version, except: [:password_digest, :token])
# => Retorna todos exceto password_digest e token

PaperTrail::Human.format_collection(versions, only: [:name])
# => Funciona também na collection
```

**Implementação:**
- `Presenter#call` e `BatchPresenter#call` aceitam `only:` / `except:` kwargs
- Filtro aplicado ANTES da formatação (evita resolver campos que serão descartados)
- `only` tem precedência sobre `except` se ambos fornecidos

**Specs:**
- `only:` filtra corretamente
- `except:` exclui corretamente
- Campos ignorados globais + filtro local combinam
- `format_collection` respeita filtros

---

### 7. Formatação de datas e números

**Problema:** Campos `Date`, `DateTime`, `BigDecimal` aparecem como representação Ruby crua (`"2026-05-29"`, `"0.4253e4"`).

**Solução:** Novos resolvers `:date` e `:number`.

**API:**
```ruby
config.register 'Invoice' do |m|
  m.field :due_date, :date, format: '%d/%m/%Y'
  m.field :amount, :number, format: :currency, unit: 'R$'
  m.field :rate, :number, format: :percentage
end

# Output:
{ field: "Vencimento", previous_value: "01/05/2026", value: "15/06/2026" }
{ field: "Valor", previous_value: "R$ 1.500,00", value: "R$ 2.300,00" }
{ field: "Taxa", previous_value: "12,5%", value: "15,0%" }
```

**Implementação:**
- `Adapters::Resolvers::Date` — usa `strftime` ou `I18n.l`
- `Adapters::Resolvers::Number` — usa `format` ou helpers de número
- Ambos com fallback para `.to_s` se parsing falhar

**Specs:**
- Date com formato customizado
- Date com formato I18n
- Number como currency
- Number como percentage
- Fallback para valor inválido

---

### 8. Output em formatos alternativos

**Problema:** Nem todo consumidor quer hash. Emails precisam de HTML, Slack precisa de Markdown, logs precisam de texto plano.

**Solução:** Formatters de output plugáveis.

**API:**
```ruby
PaperTrail::Human.format(version, as: :hash)      # default
PaperTrail::Human.format(version, as: :markdown)
PaperTrail::Human.format(version, as: :text)
PaperTrail::Human.format(version, as: :html)
```

**Output Markdown:**
```markdown
**João Silva** atualizou **User** em 29/05/2026:
- **Nome**: João → João Silva
- **Empresa**: Acme → Globex
```

**Output Text:**
```
João Silva atualizou User em 29/05/2026:
  Nome: João → João Silva
  Empresa: Acme → Globex
```

**Implementação:**
- Port `Ports::OutputFormatter` com `#render(formatted_hash) → String`
- Adapters: `Outputs::Hash`, `Outputs::Markdown`, `Outputs::Text`, `Outputs::Html`
- Registráveis via config para formatos customizados

---

### 9. Agrupamento por período (Timeline)

**Problema:** Em UIs de timeline, mostrar 200 versions flat é ruim. Agrupar por dia/hora facilita a leitura.

**Solução:** Método `timeline` que agrupa versions formatadas.

**API:**
```ruby
PaperTrail::Human.timeline(versions, group_by: :day)
# => {
#   "29/05/2026" => [formatted_version_1, formatted_version_2],
#   "28/05/2026" => [formatted_version_3]
# }

PaperTrail::Human.timeline(versions, group_by: :hour)
PaperTrail::Human.timeline(versions, group_by: ->(v) { v[:model] })
```

**Implementação:**
- Usa `format_collection` internamente (batch loading)
- Agrupa resultado por chave derivada de `created_at` ou lambda customizado
- Retorna hash ordenado (mais recente primeiro)

---

### 10. Hooks/Callbacks

**Problema:** Às vezes o output precisa de dados extras que não vêm do Version: avatar URL, link para o registro, badge de permissão.

**Solução:** Hook `after_format` para enriquecer o hash.

**API:**
```ruby
PaperTrail::Human.configure do |config|
  config.after_format = ->(result, version) {
    result[:avatar_url] = User.find_by(id: version.whodunnit)&.avatar_url
    result[:record_url] = "/#{result[:model].underscore.pluralize}/#{result[:item_id]}"
    result
  }
end
```

**Implementação:**
- `Configuration#after_format` — lambda opcional
- Chamado no final de `Presenter#call` e `BatchPresenter#format_version`
- Recebe o hash formatado + version original, retorna hash (pode mutar ou retornar novo)

---

## Priorização Sugerida

| # | Feature | Valor | Esforço | Próximo? |
|---|---------|-------|---------|----------|
| 4 | I18n event labels | Alto (UX) | Baixo | ✓ |
| 5 | Diff mode texto | Médio (UX) | Baixo | ✓ |
| 6 | Filtro only/except | Alto (DX) | Baixo | ✓ |
| 7 | Date/Number resolvers | Médio (UX) | Médio | ✓ |
| 8 | Output formats | Médio (extensibilidade) | Médio | |
| 9 | Timeline grouping | Baixo (convenience) | Baixo | |
| 10 | Hooks/Callbacks | Baixo (extensibilidade) | Baixo | |
