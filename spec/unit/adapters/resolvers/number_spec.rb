# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaperTrail::Human::Adapters::Resolvers::Number do
  describe '#resolve' do
    context 'with default format' do
      let(:resolver) { described_class.new }

      it 'formats an integer' do
        expect(resolver.resolve(1234)).to eq('1,234.00')
      end

      it 'formats a float' do
        expect(resolver.resolve(1234.5)).to eq('1,234.50')
      end

      it 'formats a string number' do
        expect(resolver.resolve('1234.5')).to eq('1,234.50')
      end
    end

    context 'with currency format' do
      let(:resolver) { described_class.new(format: :currency, unit: 'R$') }

      it 'prepends unit' do
        expect(resolver.resolve(1500.99)).to eq('R$ 1,500.99')
      end
    end

    context 'with percentage format' do
      let(:resolver) { described_class.new(format: :percentage) }

      it 'appends percent sign' do
        expect(resolver.resolve(85.5)).to eq('85.50%')
      end
    end

    context 'with custom precision and separators' do
      let(:resolver) { described_class.new(precision: 3, delimiter: '.', separator: ',') }

      it 'applies custom formatting' do
        expect(resolver.resolve(1234.5)).to eq('1.234,500')
      end
    end

    context 'with non-numeric value' do
      let(:resolver) { described_class.new }

      it 'returns the raw value' do
        expect(resolver.resolve('abc')).to eq('abc')
      end
    end
  end
end
