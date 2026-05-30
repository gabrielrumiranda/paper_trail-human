# frozen_string_literal: true

module PaperTrail
  module Human
    class Railtie < ::Rails::Railtie
      initializer 'paper_trail_human.i18n' do
        locale_path = File.expand_path('../../../config/locales/*.yml', __dir__)
        I18n.load_path += Dir[locale_path]
      end

      initializer 'paper_trail_human.extend_version_model' do
        ActiveSupport.on_load(:active_record) do
          if PaperTrail::Human.configuration.extend_version_model
            PaperTrail::Version.include(PaperTrail::Human::VersionExtension)
          end
        end
      end
    end

    module VersionExtension
      def formatted_log
        PaperTrail::Human.format(self)
      end
    end
  end
end
