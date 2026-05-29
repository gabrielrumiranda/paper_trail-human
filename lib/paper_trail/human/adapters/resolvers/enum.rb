# frozen_string_literal: true

module PaperTrail
  module Human
    module Adapters
      module Resolvers
        class Enum
          include Ports::Resolver

          def initialize(class_name: nil, method: :label, mapping: nil, from_model: nil, **options)
            @class_name = class_name || options[:class].to_s
            @method = method
            @mapping = mapping
            @from_model = from_model
            @field = options[:field]&.to_s
            @labels = options[:labels]
          end

          def resolve(value)
            return resolve_from_model(value) if @from_model
            return @mapping[value] || value if @mapping

            klass = Object.const_get(@class_name)
            if klass.respond_to?(@method)
              klass.public_send(@method, value) || value
            else
              value
            end
          rescue NameError
            value
          end

          private

          def resolve_from_model(value)
            klass = Object.const_get(@from_model)
            enum_mapping = klass.defined_enums[@field]
            return value unless enum_mapping

            key = enum_mapping.key(value) || enum_mapping.key(value.to_i)
            return value unless key

            return @labels[key.to_sym] || @labels[key.to_s] || humanize(key) if @labels

            humanize(key)
          rescue NameError
            value
          end

          def humanize(str)
            str.to_s.tr('_', ' ').then { |s| "#{s[0].upcase}#{s[1..]}" }
          end
        end
      end
    end
  end
end
