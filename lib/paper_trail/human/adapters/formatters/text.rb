# frozen_string_literal: true

module PaperTrail
  module Human
    module Adapters
      module Formatters
        class Text
          def call(result)
            lines = [header(result)]
            result[:fields].each { |f| lines << field_line(f) }
            lines.join("\n")
          end

          private

          def header(result)
            "#{result[:event]} #{result[:model]}##{result[:item_id]} by #{result[:user]} at #{result[:created_at]}"
          end

          def field_line(field)
            if field.key?(:previous_value) && field.key?(:value)
              "  • #{field[:field]}: #{field[:previous_value]} → #{field[:value]}"
            elsif field.key?(:value)
              "  • #{field[:field]}: #{field[:value]}"
            else
              "  • #{field[:field]}: #{field[:previous_value]} (removed)"
            end
          end
        end
      end
    end
  end
end
