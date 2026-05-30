# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaperTrail::Human::Adapters::Formatters::Markdown do
  let(:result) do
    {
      user: 'John',
      event: 'Updated',
      model: 'User',
      item_id: 1,
      created_at: '2026-05-30 12:00:00',
      fields: [
        { field: 'Name', previous_value: 'Old', value: 'New' }
      ]
    }
  end

  it 'formats as markdown table' do
    output = described_class.new.call(result)

    expect(output).to include('**Updated**')
    expect(output).to include('| Field | Previous | Current |')
    expect(output).to include('| Name | Old | New |')
  end

  it 'uses — for missing values' do
    result[:fields] = [{ field: 'Name', value: 'New' }]
    output = described_class.new.call(result)

    expect(output).to include('| Name | — | New |')
  end
end
