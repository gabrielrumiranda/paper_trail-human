# frozen_string_literal: true

module PaperTrail
  module Human
    module Adapters
      module Resolvers
        class Text
          include Ports::Resolver

          DEFAULT_MAX_LENGTH = 80

          def initialize(max_length: DEFAULT_MAX_LENGTH, show_diff_stats: false, **)
            @max_length = max_length
            @show_diff_stats = show_diff_stats
          end

          def resolve(value)
            text = value.to_s
            return text if text.length <= @max_length

            truncated = "#{text[0, @max_length]}..."
            truncated += " (#{text.length} chars)" if @show_diff_stats
            truncated
          end
        end
      end
    end
  end
end
