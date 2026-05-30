# frozen_string_literal: true

module PaperTrail
  module Human
    module Adapters
      module Resolvers
        class Number
          include Ports::Resolver

          def initialize(format: :default, unit: nil, precision: 2, delimiter: ',', separator: '.', **)
            @format = format
            @unit = unit
            @precision = precision
            @delimiter = delimiter
            @separator = separator
          end

          def resolve(value)
            num = to_number(value)
            return value unless num

            case @format
            when :currency then format_currency(num)
            when :percentage then format_percentage(num)
            else format_number(num)
            end
          end

          private

          def to_number(value)
            return value if value.is_a?(Numeric)

            Float(value)
          rescue ArgumentError, TypeError
            nil
          end

          def format_number(num)
            int_part, dec_part = rounded(num).split('.')
            int_with_delimiters = int_part.gsub(/(\d)(?=(\d{3})+(?!\d))/, "\\1#{@delimiter}")
            dec_part ? "#{int_with_delimiters}#{@separator}#{dec_part}" : int_with_delimiters
          end

          def format_currency(num)
            "#{@unit} #{format_number(num)}"
          end

          def format_percentage(num)
            "#{format_number(num)}%"
          end

          def rounded(num)
            format("%<n>.#{@precision}f", n: num)
          end
        end
      end
    end
  end
end
