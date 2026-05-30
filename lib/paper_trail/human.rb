# frozen_string_literal: true

require_relative 'human/version'
require_relative 'human/configuration'
require_relative 'human/core/change_extractor'
require_relative 'human/core/field_formatter'
require_relative 'human/core/event_translator'
require_relative 'human/core/presenter'
require_relative 'human/core/batch_presenter'
require_relative 'human/core/timeline'
require_relative 'human/ports/resolver'
require_relative 'human/adapters/resolvers/relation'
require_relative 'human/adapters/resolvers/enum'
require_relative 'human/adapters/resolvers/boolean'
require_relative 'human/adapters/resolvers/custom'
require_relative 'human/adapters/resolvers/text'
require_relative 'human/adapters/resolvers/date'
require_relative 'human/adapters/resolvers/number'
require_relative 'human/adapters/formatters/text'
require_relative 'human/adapters/formatters/markdown'
require_relative 'human/adapters/formatters/html'

module PaperTrail
  module Human
    class Error < StandardError; end

    MUTEX = Mutex.new
    private_constant :MUTEX

    FORMATTERS = {
      text: Adapters::Formatters::Text,
      markdown: Adapters::Formatters::Markdown,
      html: Adapters::Formatters::Html
    }.freeze
    private_constant :FORMATTERS

    class << self
      def configuration
        @configuration || MUTEX.synchronize { @configuration ||= Configuration.new }
      end

      def configure
        yield(configuration)
      end

      def reset_configuration!
        MUTEX.synchronize { @configuration = Configuration.new }
      end

      def format(version, only: nil, except: nil, as: nil)
        result = Core::Presenter.new(configuration).call(version, only: only, except: except)
        as ? formatter(as).call(result) : result
      end

      def format_collection(versions, only: nil, except: nil, as: nil)
        results = Core::BatchPresenter.new(configuration).call(versions, only: only, except: except)
        as ? results.map { |r| formatter(as).call(r) } : results
      end

      private

      def formatter(type)
        klass = FORMATTERS[type.to_sym]
        raise Error, "Unknown format: #{type}. Available: #{FORMATTERS.keys.join(', ')}" unless klass

        klass.new
      end

      def timeline(versions, group_by: :day, only: nil, except: nil)
        Core::Timeline.new(configuration).call(versions, group_by: group_by, only: only, except: except)
      end
    end
  end
end
