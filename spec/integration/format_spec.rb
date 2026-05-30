# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaperTrail::Human do
  describe '.format' do
    it 'formats a version end-to-end with configured resolvers' do
      described_class.configure do |config|
        config.whodunnit_resolver = ->(id) { "Admin ##{id}" }

        config.register('User') do |m|
          m.field :active, :boolean, true_label: 'Ativo', false_label: 'Inativo'
          m.field :score, :custom, resolve: ->(v) { "#{v} pts" }
        end
      end

      version = instance_double(
        'PaperTrail::Version',
        item_type: 'User',
        item_id: 7,
        event: 'update',
        whodunnit: '1',
        created_at: Time.new(2026, 5, 29),
        object_changes: {
          'active' => [true, false],
          'score' => [80, 95],
          'id' => [7, 7],
          'updated_at' => %w[a b]
        },
        object: nil
      )

      result = described_class.format(version)

      expect(result[:user]).to eq('Admin #1')
      expect(result[:event]).to eq('update')
      expect(result[:model]).to eq('User')
      expect(result[:item_id]).to eq(7)
      expect(result[:fields]).to contain_exactly(
        { field: 'Active', previous_value: 'Ativo', value: 'Inativo' },
        { field: 'Score', previous_value: '80 pts', value: '95 pts' }
      )
    end
  end

  describe '.format_collection' do
    it 'formats multiple versions' do
      versions = [
        instance_double(
          'PaperTrail::Version',
          item_type: 'Post', item_id: 1, event: 'create', whodunnit: nil,
          created_at: Time.now, object_changes: { 'title' => [nil, 'Hello'] }, object: nil
        ),
        instance_double(
          'PaperTrail::Version',
          item_type: 'Post', item_id: 1, event: 'update', whodunnit: '2',
          created_at: Time.now, object_changes: { 'title' => %w[Hello World] }, object: nil
        )
      ]

      results = described_class.format_collection(versions)

      expect(results.size).to eq(2)
      expect(results.first[:event]).to eq('create')
      expect(results.last[:event]).to eq('update')
    end
  end

  describe 'output formats' do
    let(:version) do
      instance_double(
        'PaperTrail::Version',
        item_type: 'Post', item_id: 1, event: 'update', whodunnit: '1',
        created_at: Time.new(2026, 5, 30), object_changes: { 'title' => %w[Old New] }, object: nil
      )
    end

    it 'returns string with as: :text' do
      result = described_class.format(version, as: :text)

      expect(result).to be_a(String)
      expect(result).to include('Title: Old → New')
    end

    it 'returns string with as: :markdown' do
      result = described_class.format(version, as: :markdown)

      expect(result).to include('| Title | Old | New |')
    end

    it 'returns string with as: :html' do
      result = described_class.format(version, as: :html)

      expect(result).to include('<td>Title</td>')
    end

    it 'raises on unknown format' do
      expect { described_class.format(version, as: :xml) }
        .to raise_error(PaperTrail::Human::Error, /Unknown format/)
    end
  end
end
