# frozen_string_literal: true

module PaperTrail
  module Human
    module Core
      class Timeline
        GROUPINGS = {
          day: '%Y-%m-%d',
          week: '%G-W%V',
          month: '%Y-%m',
          year: '%Y'
        }.freeze

        def initialize(configuration)
          @configuration = configuration
          @batch_presenter = BatchPresenter.new(configuration)
        end

        def call(versions, group_by: :day, only: nil, except: nil)
          formatted = @batch_presenter.call(versions, only: only, except: except)
          format_str = GROUPINGS.fetch(group_by.to_sym) do
            raise Error, "Unknown group_by: #{group_by}. Available: #{GROUPINGS.keys.join(', ')}"
          end

          formatted.group_by { |r| r[:created_at].strftime(format_str) }
        end
      end
    end
  end
end
