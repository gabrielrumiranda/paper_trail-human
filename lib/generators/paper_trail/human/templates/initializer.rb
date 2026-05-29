# frozen_string_literal: true

PaperTrail::Human.configure do |config|
  # Resolver quem fez a alteração (recebe whodunnit ID, retorna nome)
  # config.whodunnit_resolver = ->(id) { User.find_by(id: id)&.name }

  # Campos ignorados globalmente (default: id, created_at, updated_at)
  # config.ignored_fields = %w[id created_at updated_at]

  # Resolver customizado para nomes de campos (usa I18n/human_attribute_name)
  # config.field_name_resolver = ->(field_name, item_type) {
  #   item_type.constantize.human_attribute_name(field_name)
  # }

  # Configuração por model:
  #
  # config.register 'User' do |m|
  #   m.field :role, :enum, class_name: 'UserRole', method: :label
  #   m.field :company_id, :relation, class_name: 'Company', attribute: :name
  #   m.field :active, :boolean, true_label: 'Ativo', false_label: 'Inativo'
  #   m.field :score, :custom, resolve: ->(v) { "#{v} pontos" }
  # end
end
