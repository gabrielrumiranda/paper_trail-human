# frozen_string_literal: true

module PaperTrail
  module Human
    module Ports
      module Resolver
        def resolve(value)
          raise NotImplementedError, "#{self.class}#resolve must be implemented"
        end
      end
    end
  end
end
