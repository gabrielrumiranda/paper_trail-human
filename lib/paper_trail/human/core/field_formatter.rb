# frozen_string_literal: true

module PaperTrail
  module Human
    module Core
      class FieldFormatter
        RESOLVER_MAP = {
          relation: 'PaperTrail::Human::Adapters::Resolvers::Relation',
          enum: 'PaperTrail::Human::Adapters::Resolvers::Enum',
          boolean: 'PaperTrail::Human::Adapters::Resolvers::Boolean',
          custom: 'PaperTrail::Human::Adapters::Resolvers::Custom'
        }.freeze

        def initialize(model_config, item_type, field_name_resolver: nil, preloaded: nil)
          @model_config = model_config
          @item_type = item_type
          @field_name_resolver = field_name_resolver
          @preloaded = preloaded || {}
        end

        def call(field_name, previous_value, new_value)
          config = field_config(field_name)
          resolver = build_resolver(config)

          {
            field: human_field_name(field_name),
            previous_value: resolve_value(resolver, previous_value),
            value: resolve_value(resolver, new_value)
          }
        end

        private

        def field_config(field_name)
          return nil unless @model_config

          @model_config.fields[field_name.to_s]
        end

        def build_resolver(config)
          return nil unless config

          class_name = RESOLVER_MAP[config[:type]]
          raise Error, "Unknown resolver type: #{config[:type]}" unless class_name

          klass = Object.const_get(class_name)
          opts = config[:options]
          opts = opts.merge(cache: relation_cache(config)) if config[:type] == :relation
          klass.new(**opts)
        end

        def relation_cache(config)
          class_name = config[:options][:class_name] || config[:options][:class].to_s
          attribute = config[:options][:attribute] || :name
          @preloaded[[class_name, attribute]] || {}
        end

        def resolve_value(resolver, value)
          return value unless resolver
          return value if value.nil?

          resolver.resolve(value)
        end

        def human_field_name(field_name)
          return @field_name_resolver.call(field_name, @item_type) if @field_name_resolver

          default_human_field_name(field_name)
        end

        def default_human_field_name(field_name)
          field_name.to_s.delete_suffix('_id').tr('_', ' ').then { |s| "#{s[0].upcase}#{s[1..]}" }
        end
      end
    end
  end
end
