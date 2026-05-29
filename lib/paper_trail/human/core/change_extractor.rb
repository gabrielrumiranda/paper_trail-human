# frozen_string_literal: true

require 'yaml'
require 'json'
require 'bigdecimal'

module PaperTrail
  module Human
    module Core
      class ChangeExtractor
        def call(version)
          changes = extract_object_changes(version)
          return changes if changes

          infer_from_object(version)
        end

        private

        def extract_object_changes(version)
          return nil unless version.respond_to?(:object_changes) && version.object_changes

          raw = version.object_changes
          parse(raw)
        end

        def infer_from_object(version)
          return {} unless version.respond_to?(:object) && version.object

          parsed = parse(version.object)
          return {} unless parsed.is_a?(Hash)

          case version.event
          when 'create'
            parsed.transform_values { |v| [nil, v] }
          when 'destroy'
            parsed.transform_values { |v| [v, nil] }
          else
            {}
          end
        end

        def parse(raw)
          return raw if raw.is_a?(Hash)

          JSON.parse(raw)
        rescue JSON::ParserError
          YAML.safe_load(raw, permitted_classes: [Time, Date, DateTime, BigDecimal, Symbol])
        rescue StandardError
          {}
        end
      end
    end
  end
end
