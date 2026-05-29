# frozen_string_literal: true

module PaperTrail
  module Human
    module Core
      class BatchPresenter
        def initialize(configuration)
          @configuration = configuration
          @change_extractor = ChangeExtractor.new
        end

        def call(versions)
          versions_data = versions.map { |v| [v, @change_extractor.call(v)] }
          preloaded = preload_relations(versions_data)

          versions_data.map { |version, changes| format_version(version, changes, preloaded) }
        end

        private

        def format_version(version, changes, preloaded)
          model_config = @configuration.config_for(version.item_type)
          formatter = FieldFormatter.new(
            model_config,
            version.item_type,
            field_name_resolver: @configuration.field_name_resolver,
            preloaded: preloaded
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

        def preload_relations(versions_data)
          relation_fields = collect_relation_fields(versions_data)
          return {} if relation_fields.empty?

          relation_fields.each_with_object({}) do |(key, ids), cache|
            class_name, attribute = key
            cache[key] = load_records(class_name, attribute, ids)
          end
        end

        def collect_relation_fields(versions_data)
          result = Hash.new { |h, k| h[k] = Set.new }

          versions_data.each do |version, changes|
            collect_from_version(result, version, changes)
          end

          result
        end

        def collect_from_version(result, version, changes)
          model_config = @configuration.config_for(version.item_type)
          return unless model_config

          changes.each do |field, values|
            field_cfg = model_config.fields[field.to_s]
            next unless field_cfg && field_cfg[:type] == :relation

            key = relation_key(field_cfg)
            Array(values).compact.each { |v| result[key].add(v) }
          end
        end

        def relation_key(field_cfg)
          class_name = field_cfg[:options][:class_name] || field_cfg[:options][:class].to_s
          attribute = field_cfg[:options][:attribute] || :name
          [class_name, attribute]
        end

        def load_records(class_name, attribute, ids)
          klass = Object.const_get(class_name)
          klass.where(id: ids.to_a).to_h do |record|
            [record.id, record.public_send(attribute)]
          end
        rescue NameError
          {}
        end
      end
    end
  end
end
