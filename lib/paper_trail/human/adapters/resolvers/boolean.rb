# frozen_string_literal: true

module PaperTrail
  module Human
    module Adapters
      module Resolvers
        class Boolean
          include Ports::Resolver

          def initialize(true_label: 'Yes', false_label: 'No', **)
            @true_label = true_label
            @false_label = false_label
          end

          def resolve(value)
            value ? @true_label : @false_label
          end
        end
      end
    end
  end
end
