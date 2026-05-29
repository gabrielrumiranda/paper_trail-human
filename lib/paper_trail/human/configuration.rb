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
    end

    class ModelConfig
      attr_reader :fields

      def initialize
        @fields = {}
      end

      def field(name, type, **options)
        @fields[name.to_s] = { type: type, options: options }
      end

      def freeze
        @fields.freeze
        super
      end
    end
  end
end
