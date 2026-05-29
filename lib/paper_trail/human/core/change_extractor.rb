# frozen_string_literal: true

require 'yaml'
require 'json'
require 'bigdecimal'

module PaperTrail
  module Human
    module Core
      class ChangeExtractor
        YAML_PERMITTED_CLASSES = [Time, Date, DateTime, BigDecimal, Symbol].freeze

        def call(version)
          changes = extract_object_changes(version)
          return changes if changes

          warn_missing_object_changes(version) if version.event == 'update'
          infer_from_object(version)
        end

        private

        def warn_missing_object_changes(version)
          return if @warned

          @warned = true
          message = "[paper_trail-human] Version ##{version.id} (update) has no object_changes. " \
                    'Add the object_changes column to your versions table for full update tracking.'
          if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
            Rails.logger.warn(message)
          else
            warn message
          end
        end

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
          YAML.safe_load(raw, permitted_classes: yaml_permitted_classes, aliases: true)
        rescue StandardError
          {}
        end

        def yaml_permitted_classes
          classes = YAML_PERMITTED_CLASSES.dup
          classes << ActiveSupport::TimeWithZone if defined?(ActiveSupport::TimeWithZone)
          classes << ActiveSupport::TimeZone if defined?(ActiveSupport::TimeZone)
          classes << ActiveSupport::Duration if defined?(ActiveSupport::Duration)
          classes
        end
      end
    end
  end
end
