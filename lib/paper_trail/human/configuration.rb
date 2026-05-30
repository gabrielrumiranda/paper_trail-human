# frozen_string_literal: true

module PaperTrail
  module Human
    class Configuration
      DEFAULT_IGNORED_FIELDS = %w[id created_at updated_at].freeze

      attr_accessor :whodunnit_resolver, :extend_version_model, :field_name_resolver, :translate_events
      attr_reader :ignored_fields

      def initialize
        @model_configs = {}
        @ignored_fields = DEFAULT_IGNORED_FIELDS.dup
        @whodunnit_resolver = nil
        @field_name_resolver = nil
        @translate_events = false
        @extend_version_model = false
        @mutex = Mutex.new
      end

      def ignored_fields=(fields)
        @ignored_fields = Array(fields).map(&:to_s)
      end

      def register(model_name, &block)
        model_config = ModelConfig.new
        yield(model_config)
        @mutex.synchronize { @model_configs[model_name.to_s] = model_config.freeze }
      end

      def config_for(model_name)
        @model_configs[model_name.to_s]
      end

      def resolve_whodunnit(id)
        return id unless whodunnit_resolver

        whodunnit_resolver.call(id)
      end

      def resolve_item_name(version)
        model_config = config_for(version.item_type)
        return nil unless model_config&.item_name_attribute

        attr = model_config.item_name_attribute
        return attr.call(version) if attr.respond_to?(:call)

        item = find_item(version)
        item&.public_send(attr)
      rescue NoMethodError, ActiveRecord::RecordNotFound
        nil
      end

      private

      def find_item(version)
        klass = Object.const_get(version.item_type)
        klass.find_by(id: version.item_id)
      rescue NameError
        nil
      end
    end

    class ModelConfig
      attr_reader :fields, :item_name_attribute

      def initialize
        @fields = {}
        @item_name_attribute = nil
      end

      def field(name, type, **options)
        @fields[name.to_s] = { type: type, options: options }
      end

      def item_name(attribute_or_lambda)
        @item_name_attribute = attribute_or_lambda
      end

      def freeze
        @fields.freeze
        super
      end
    end
  end
end
