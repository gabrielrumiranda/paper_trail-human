# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaperTrail::Human::Adapters::Resolvers::Boolean do
  describe '#resolve' do
    it 'returns true_label for truthy value' do
      resolver = described_class.new(true_label: 'Ativo', false_label: 'Inativo')

      expect(resolver.resolve(true)).to eq('Ativo')
    end

    it 'returns false_label for falsy value' do
      resolver = described_class.new(true_label: 'Ativo', false_label: 'Inativo')

      expect(resolver.resolve(false)).to eq('Inativo')
    end

    it 'uses default labels' do
      resolver = described_class.new

      expect(resolver.resolve(true)).to eq('Yes')
      expect(resolver.resolve(false)).to eq('No')
    end
  end
end
