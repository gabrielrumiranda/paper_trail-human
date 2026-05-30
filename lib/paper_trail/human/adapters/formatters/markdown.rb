# frozen_string_literal: true

module PaperTrail
  module Human
    module Adapters
      module Formatters
        class Markdown
          def call(result)
            lines = [header(result), '']
            lines << '| Field | Previous | Current |'
            lines << '|-------|----------|---------|'
            result[:fields].each { |f| lines << table_row(f) }
            lines.join("\n")
          end

          private

          def header(result)
            "**#{result[:event]}** `#{result[:model]}##{result[:item_id]}` by #{result[:user]} at #{result[:created_at]}"
          end

          def table_row(field)
            prev = field.fetch(:previous_value, '—')
            curr = field.fetch(:value, '—')
            "| #{field[:field]} | #{prev} | #{curr} |"
          end
        end
      end
    end
  end
end
