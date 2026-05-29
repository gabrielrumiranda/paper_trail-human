# frozen_string_literal: true

module PaperTrail
  module Human
    module Adapters
      module Resolvers
        class Custom
          include Ports::Resolver

          def initialize(resolve:, **)
            @proc = resolve
          end

          def resolve(value)
            @proc.call(value)
          end
        end
      end
    end
  end
end
