# frozen_string_literal: true

module PaperTrail
  module Human
    module Core
      class Presenter
        def initialize(configuration)
          @configuration = configuration
          @change_extractor = ChangeExtractor.new
        end

        def call(version, only: nil, except: nil)
          changes = @change_extractor.call(version)
          model_config = @configuration.config_for(version.item_type)
          formatter = FieldFormatter.new(
            model_config,
            version.item_type,
            field_name_resolver: @configuration.field_name_resolver
          )

          result = {
            user: @configuration.resolve_whodunnit(version.whodunnit),
            event: EventTranslator.call(version.event, translate: @configuration.translate_events),
            model: version.item_type,
            item_id: version.item_id,
            created_at: version.created_at,
            fields: build_fields(changes, formatter, version.event, only: only, except: except)
          }

          item_name = @configuration.resolve_item_name(version)
          result[:item_name] = item_name if item_name

          result
        end

        private

        def build_fields(changes, formatter, event, only: nil, except: nil)
          changes
            .reject { |field, _| @configuration.ignored_fields.include?(field.to_s) }
            .select { |field, _| filter_field?(field, only, except) }
            .map { |field, values| format_field(formatter, field, values, event) }
        end

        def filter_field?(field, only, except)
          field_s = field.to_s
          return only.map(&:to_s).include?(field_s) if only

          return !except.map(&:to_s).include?(field_s) if except

          true
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
