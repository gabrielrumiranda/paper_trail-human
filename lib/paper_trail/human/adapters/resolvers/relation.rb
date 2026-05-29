# frozen_string_literal: true

module PaperTrail
  module Human
    module Adapters
      module Resolvers
        class Relation
          include Ports::Resolver

          def initialize(class_name: nil, attribute: :name, **options)
            @class_name = class_name || options[:class].to_s
            @attribute = attribute
          end

          def resolve(value)
            klass = Object.const_get(@class_name)
            record = klass.find_by(id: value)
            record&.public_send(@attribute) || value
          rescue NameError
            value
          end
        end
      end
    end
  end
end
