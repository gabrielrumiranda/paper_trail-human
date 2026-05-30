# frozen_string_literal: true

module PaperTrail
  module Human
    module Adapters
      module Resolvers
        class Date
          include Ports::Resolver

          def initialize(format: '%Y-%m-%d', **)
            @format = format
          end

          def resolve(value)
            date = parse_date(value)
            return value unless date

            date.strftime(@format)
          rescue ArgumentError
            value
          end

          private

          def parse_date(value)
            return value if value.respond_to?(:strftime)

            ::Date.parse(value.to_s)
          rescue ArgumentError, TypeError
            nil
          end
        end
      end
    end
  end
end
