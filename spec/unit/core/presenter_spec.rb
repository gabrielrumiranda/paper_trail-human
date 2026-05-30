# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaperTrail::Human::Core::Presenter do
  subject(:presenter) { described_class.new(PaperTrail::Human.configuration) }

  let(:version) do
    instance_double(
      'PaperTrail::Version',
      item_type: 'User',
      item_id: 1,
      event: 'update',
      whodunnit: '42',
      created_at: Time.new(2026, 1, 1, 12, 0, 0),
      object_changes: { 'name' => %w[Old New], 'id' => [1, 1], 'updated_at' => %w[a b] },
      object: nil
    )
  end

  describe '#call' do
    it 'returns structured hash with event info' do
      result = presenter.call(version)

      expect(result[:event]).to eq('update')
      expect(result[:model]).to eq('User')
      expect(result[:item_id]).to eq(1)
    end

    it 'filters ignored fields' do
      result = presenter.call(version)
      field_names = result[:fields].map { |f| f[:field] }

      expect(field_names).not_to include('Id', 'Updated at')
    end

    it 'resolves whodunnit when resolver configured' do
      PaperTrail::Human.configure do |config|
        config.whodunnit_resolver = ->(id) { "User ##{id}" }
      end

      result = presenter.call(version)

      expect(result[:user]).to eq('User #42')
    end

    it 'returns raw whodunnit when no resolver' do
      result = presenter.call(version)

      expect(result[:user]).to eq('42')
    end

    context 'with only filter' do
      it 'returns only specified fields' do
        result = presenter.call(version, only: [:name])
        field_names = result[:fields].map { |f| f[:field] }

        expect(field_names).to eq(['Name'])
      end
    end

    context 'with except filter' do
      it 'excludes specified fields' do
        result = presenter.call(version, except: [:name])
        field_names = result[:fields].map { |f| f[:field] }

        expect(field_names).not_to include('Name')
      end
    end
  end
end
