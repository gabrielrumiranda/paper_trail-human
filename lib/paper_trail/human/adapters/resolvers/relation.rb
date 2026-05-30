# frozen_string_literal: true

module PaperTrail
  module Human
    module Adapters
      module Resolvers
        class Relation
          include Ports::Resolver

          def initialize(class_name: nil, attribute: :name, cache: nil, **options)
            @class_name = class_name || options[:class].to_s
            @attribute = attribute
            @cache = cache || {}
          end

          def resolve(value)
            return @cache[value] || @cache[value.to_i] || value if @cache.any?

            klass = safe_const_get(@class_name)
            return value unless klass

            record = klass.find_by(id: value)
            record&.public_send(@attribute) || value
          end

          private

          def safe_const_get(name)
            klass = Object.const_get(name)
            return klass if defined?(ActiveRecord::Base) && klass < ActiveRecord::Base
            return klass if klass.respond_to?(:find_by)

            nil
          rescue NameError
            nil
          end
        end
      end
    end
  end
end
