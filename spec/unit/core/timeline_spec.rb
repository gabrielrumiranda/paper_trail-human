# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaperTrail::Human::Core::Timeline do
  subject(:timeline) { described_class.new(PaperTrail::Human.configuration) }

  let(:versions) do
    [
      instance_double('PaperTrail::Version',
                      item_type: 'Post', item_id: 1, event: 'create', whodunnit: '1',
                      created_at: Time.new(2026, 5, 28, 10, 0, 0),
                      object_changes: { 'title' => [nil, 'A'] }, object: nil),
      instance_double('PaperTrail::Version',
                      item_type: 'Post', item_id: 1, event: 'update', whodunnit: '1',
                      created_at: Time.new(2026, 5, 28, 14, 0, 0),
                      object_changes: { 'title' => %w[A B] }, object: nil),
      instance_double('PaperTrail::Version',
                      item_type: 'Post', item_id: 1, event: 'update', whodunnit: '2',
                      created_at: Time.new(2026, 5, 30, 9, 0, 0),
                      object_changes: { 'title' => %w[B C] }, object: nil)
    ]
  end

  describe '#call' do
    it 'groups by day' do
      result = timeline.call(versions, group_by: :day)

      expect(result.keys).to eq(%w[2026-05-28 2026-05-30])
      expect(result['2026-05-28'].size).to eq(2)
      expect(result['2026-05-30'].size).to eq(1)
    end

    it 'groups by month' do
      result = timeline.call(versions, group_by: :month)

      expect(result.keys).to eq(%w[2026-05])
      expect(result['2026-05'].size).to eq(3)
    end

    it 'groups by week' do
      result = timeline.call(versions, group_by: :week)

      expect(result.values.flatten.size).to eq(3)
    end

    it 'raises on unknown group_by' do
      expect { timeline.call(versions, group_by: :hour) }
        .to raise_error(PaperTrail::Human::Error, /Unknown group_by/)
    end
  end
end
