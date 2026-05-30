# frozen_string_literal: true

module PaperTrail
  module Human
    module Core
      module EventTranslator
        DEFAULT_LABELS = {
          'create' => 'Created',
          'update' => 'Updated',
          'destroy' => 'Destroyed'
        }.freeze

        def self.call(event, translate:)
          return event unless translate

          return event unless defined?(I18n)

          I18n.t("paper_trail_human.events.#{event}", default: nil) || DEFAULT_LABELS[event] || event
        rescue I18n::InvalidLocale, I18n::InvalidLocaleData
          DEFAULT_LABELS[event] || event
        end
      end
    end
  end
end
