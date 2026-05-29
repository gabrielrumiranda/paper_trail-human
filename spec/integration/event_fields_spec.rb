# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Event-specific field formatting' do
  describe 'create event' do
    it 'omits previous_value from fields' do
      version = instance_double(
        'PaperTrail::Version',
        item_type: 'User', item_id: 1, event: 'create', whodunnit: nil,
        created_at: Time.now, object_changes: { 'name' => [nil, 'João'] }, object: nil
      )

      result = PaperTrail::Human.format(version)

      expect(result[:fields].first).to eq(field: 'Name', value: 'João')
      expect(result[:fields].first).not_to have_key(:previous_value)
    end
  end

  describe 'destroy event' do
    it 'omits value from fields' do
      version = instance_double(
        'PaperTrail::Version',
        item_type: 'User', item_id: 1, event: 'destroy', whodunnit: nil,
        created_at: Time.now, object_changes: { 'name' => ['João', nil] }, object: nil
      )

      result = PaperTrail::Human.format(version)

      expect(result[:fields].first).to eq(field: 'Name', previous_value: 'João')
      expect(result[:fields].first).not_to have_key(:value)
    end
  end

  describe 'update event' do
    it 'includes both previous_value and value' do
      version = instance_double(
        'PaperTrail::Version',
        item_type: 'User', item_id: 1, event: 'update', whodunnit: nil,
        created_at: Time.now, object_changes: { 'name' => %w[Old New] }, object: nil
      )

      result = PaperTrail::Human.format(version)

      expect(result[:fields].first).to eq(field: 'Name', previous_value: 'Old', value: 'New')
    end
  end
end
