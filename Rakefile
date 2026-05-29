# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/unit/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:spec_integration) do |t|
  t.pattern = 'spec/integration/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:spec_all) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

RuboCop::RakeTask.new

task default: %i[rubocop spec spec_integration]
