# frozen_string_literal: true

module PaperTrail
  module Human
    module Adapters
      module Resolvers
        class Enum
          include Ports::Resolver

          def initialize(class_name: nil, method: :label, mapping: nil, **options)
            @class_name = class_name || options[:class].to_s
            @method = method
            @mapping = mapping
          end

          def resolve(value)
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
        end
      end
    end
  end
end
