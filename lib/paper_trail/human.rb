# frozen_string_literal: true

require_relative 'human/version'
require_relative 'human/configuration'
require_relative 'human/core/change_extractor'
require_relative 'human/core/field_formatter'
require_relative 'human/core/presenter'
require_relative 'human/core/batch_presenter'
require_relative 'human/ports/resolver'
require_relative 'human/adapters/resolvers/relation'
require_relative 'human/adapters/resolvers/enum'
require_relative 'human/adapters/resolvers/boolean'
require_relative 'human/adapters/resolvers/custom'
require_relative 'human/adapters/resolvers/text'

module PaperTrail
  module Human
    class Error < StandardError; end

    MUTEX = Mutex.new
    private_constant :MUTEX

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

      def format(version)
        Core::Presenter.new(configuration).call(version)
      end

      def format_collection(versions)
        Core::BatchPresenter.new(configuration).call(versions)
      end
    end
  end
end
