# frozen_string_literal: true

require_relative 'lib/paper_trail/human/version'

Gem::Specification.new do |spec|
  spec.name = 'paper_trail-human'
  spec.version = PaperTrail::Human::VERSION
  spec.authors = ['Gabriel']
  spec.summary = 'Transforms PaperTrail versions into human-readable hashes for audit logs.'
  spec.description = 'Resolves foreign keys, enums, booleans and custom transformations ' \
                     'from PaperTrail::Version into structured, UI-ready hashes.'
  spec.homepage = 'https://github.com/gabriel/paper_trail-human'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*', 'LICENSE.txt', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 5.2'
  spec.add_dependency 'paper_trail', '>= 9.0'
end
