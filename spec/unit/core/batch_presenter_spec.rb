# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaperTrail::Human::Core::BatchPresenter do
  subject(:batch_presenter) { described_class.new(PaperTrail::Human.configuration) }

  describe '#call' do
    it 'formats multiple versions' do
      versions = [
        instance_double(
          'PaperTrail::Version',
          item_type: 'Post', item_id: 1, event: 'create', whodunnit: nil,
          created_at: Time.now, object_changes: { 'title' => [nil, 'Hello'] }, object: nil
        ),
        instance_double(
          'PaperTrail::Version',
          item_type: 'Post', item_id: 1, event: 'update', whodunnit: '1',
          created_at: Time.now, object_changes: { 'title' => %w[Hello World] }, object: nil
        )
      ]

      results = batch_presenter.call(versions)

      expect(results.size).to eq(2)
      expect(results.first[:event]).to eq('create')
      expect(results.last[:event]).to eq('update')
    end

    it 'uses preloaded cache for relation resolvers' do
      company_class = Class.new do
        def self.where(id:)
          records = { 1 => 'Acme', 2 => 'Globex' }
          id.filter_map do |i|
            next unless records[i]

            obj = Object.new
            obj.define_singleton_method(:id) { i }
            obj.define_singleton_method(:name) { records[i] }
            obj
          end
        end
      end
      stub_const('Company', company_class)

      PaperTrail::Human.configure do |config|
        config.register('User') do |m|
          m.field :company_id, :relation, class_name: 'Company', attribute: :name
        end
      end

      versions = [
        instance_double(
          'PaperTrail::Version',
          item_type: 'User', item_id: 1, event: 'update', whodunnit: nil,
          created_at: Time.now, object_changes: { 'company_id' => [1, 2] }, object: nil
        ),
        instance_double(
          'PaperTrail::Version',
          item_type: 'User', item_id: 2, event: 'update', whodunnit: nil,
          created_at: Time.now, object_changes: { 'company_id' => [2, 1] }, object: nil
        )
      ]

      results = batch_presenter.call(versions)

      expect(results[0][:fields].first[:previous_value]).to eq('Acme')
      expect(results[0][:fields].first[:value]).to eq('Globex')
      expect(results[1][:fields].first[:previous_value]).to eq('Globex')
      expect(results[1][:fields].first[:value]).to eq('Acme')
    end

    it 'falls back gracefully when class does not exist' do
      PaperTrail::Human.configure do |config|
        config.register('User') do |m|
          m.field :company_id, :relation, class_name: 'NonExistent', attribute: :name
        end
      end

      versions = [
        instance_double(
          'PaperTrail::Version',
          item_type: 'User', item_id: 1, event: 'update', whodunnit: nil,
          created_at: Time.now, object_changes: { 'company_id' => [1, 2] }, object: nil
        )
      ]

      results = batch_presenter.call(versions)

      expect(results[0][:fields].first[:previous_value]).to eq(1)
      expect(results[0][:fields].first[:value]).to eq(2)
    end
  end
end
