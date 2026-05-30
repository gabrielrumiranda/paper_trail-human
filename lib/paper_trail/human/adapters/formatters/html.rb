# frozen_string_literal: true

module PaperTrail
  module Human
    module Adapters
      module Formatters
        class Html
          def call(result)
            [
              %(<div class="paper-trail-version">),
              "  <p>#{header(result)}</p>",
              '  <table>',
              '    <thead><tr><th>Field</th><th>Previous</th><th>Current</th></tr></thead>',
              '    <tbody>',
              *result[:fields].map { |f| table_row(f) },
              '    </tbody>',
              '  </table>',
              '</div>'
            ].join("\n")
          end

          private

          def header(result)
            "<strong>#{escape(result[:event])}</strong> #{escape(result[:model])}##{result[:item_id]} by #{escape(result[:user].to_s)}"
          end

          def table_row(field)
            prev = escape(field.fetch(:previous_value, '—').to_s)
            curr = escape(field.fetch(:value, '—').to_s)
            "      <tr><td>#{escape(field[:field])}</td><td>#{prev}</td><td>#{curr}</td></tr>"
          end

          def escape(str)
            str.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
          end
        end
      end
    end
  end
end
