# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaperTrail::Human::Adapters::Resolvers::Date do
  describe '#resolve' do
    context 'with default format' do
      let(:resolver) { described_class.new }

      it 'formats a Date object' do
        expect(resolver.resolve(Date.new(2026, 5, 30))).to eq('2026-05-30')
      end

      it 'formats a string date' do
        expect(resolver.resolve('2026-05-30')).to eq('2026-05-30')
      end

      it 'formats a Time object' do
        expect(resolver.resolve(Time.new(2026, 5, 30, 14, 0, 0))).to eq('2026-05-30')
      end
    end

    context 'with custom format' do
      let(:resolver) { described_class.new(format: '%d/%m/%Y') }

      it 'applies the format' do
        expect(resolver.resolve(Date.new(2026, 5, 30))).to eq('30/05/2026')
      end
    end

    context 'with unparseable value' do
      let(:resolver) { described_class.new }

      it 'returns the raw value' do
        expect(resolver.resolve('not a date')).to eq('not a date')
      end
    end
  end
end
