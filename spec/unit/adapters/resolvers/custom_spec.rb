# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaperTrail::Human::Adapters::Resolvers::Custom do
  describe '#resolve' do
    it 'applies the lambda to the value' do
      resolver = described_class.new(resolve: ->(v) { "#{v} pontos" })

      expect(resolver.resolve(10)).to eq('10 pontos')
    end

    it 'works with complex transformations' do
      resolver = described_class.new(resolve: ->(v) { v.to_s.upcase })

      expect(resolver.resolve('hello')).to eq('HELLO')
    end
  end
end
