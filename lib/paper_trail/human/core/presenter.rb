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
            event: version.event,
            model: version.item_type,
            item_id: version.item_id,
            created_at: version.created_at,
            fields: build_fields(changes, formatter)
          }
        end

        private

        def build_fields(changes, formatter)
          changes
            .reject { |field, _| @configuration.ignored_fields.include?(field.to_s) }
            .map { |field, values| format_field(formatter, field, values) }
        end

        def format_field(formatter, field, values)
          previous_value, new_value = Array(values)
          formatter.call(field, previous_value, new_value)
        end
      end
    end
  end
end
