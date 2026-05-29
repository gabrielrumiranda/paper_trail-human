# frozen_string_literal: true

module PaperTrail
  module Human
    module Core
      class Presenter
        def initialize(configuration)
          @configuration = configuration
          @change_extractor = ChangeExtractor.new
        end

        def call(version)
          changes = @change_extractor.call(version)
          model_config = @configuration.config_for(version.item_type)
          formatter = FieldFormatter.new(
            model_config,
            version.item_type,
            field_name_resolver: @configuration.field_name_resolver
          )

          {
            user: @configuration.resolve_whodunnit(version.whodunnit),
            event: EventTranslator.call(version.event, translate: @configuration.translate_events),
            model: version.item_type,
            item_id: version.item_id,
            created_at: version.created_at,
            fields: build_fields(changes, formatter, version.event)
          }
        end

        private

        def build_fields(changes, formatter, event)
          changes
            .reject { |field, _| @configuration.ignored_fields.include?(field.to_s) }
            .map { |field, values| format_field(formatter, field, values, event) }
        end

        def format_field(formatter, field, values, event)
          previous_value, new_value = Array(values)
          result = formatter.call(field, previous_value, new_value)

          case event
          when 'create'
            result.delete(:previous_value)
          when 'destroy'
            result.delete(:value)
          end

          result
        end
      end
    end
  end
end
