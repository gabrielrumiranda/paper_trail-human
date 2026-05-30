# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaperTrail::Human::Adapters::Resolvers::Text do
  describe '#resolve' do
    context 'with short text' do
      it 'returns text unchanged' do
        resolver = described_class.new(max_length: 50)

        expect(resolver.resolve('Hello world')).to eq('Hello world')
      end
    end

    context 'with long text' do
      it 'truncates with ellipsis' do
        resolver = described_class.new(max_length: 10)

        expect(resolver.resolve('Hello world, this is long')).to eq('Hello worl...')
      end
    end

    context 'with show_diff_stats' do
      it 'appends char count' do
        resolver = described_class.new(max_length: 10, show_diff_stats: true)
        text = 'Hello world, this is long'

        expect(resolver.resolve(text)).to eq("Hello worl... (#{text.length} chars)")
      end
    end

    context 'with default max_length' do
      it 'uses 80 chars' do
        resolver = described_class.new
        short = 'a' * 80
        long = 'a' * 81

        expect(resolver.resolve(short)).to eq(short)
        expect(resolver.resolve(long)).to eq("#{'a' * 80}...")
      end
    end
  end
end
