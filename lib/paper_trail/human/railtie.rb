# frozen_string_literal: true

module PaperTrail
  module Human
    class Railtie < ::Rails::Railtie
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
