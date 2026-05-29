# frozen_string_literal: true

require 'rails/generators'

module PaperTrail
  module Human
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Creates a PaperTrail::Human initializer'

      def copy_initializer
        template 'initializer.rb', 'config/initializers/paper_trail_human.rb'
      end
    end
  end
end
