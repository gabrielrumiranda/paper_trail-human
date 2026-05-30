# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaperTrail::Human::Adapters::Formatters::Html do
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

  it 'formats as HTML table' do
    output = described_class.new.call(result)

    expect(output).to include('<div class="paper-trail-version">')
    expect(output).to include('<strong>Updated</strong>')
    expect(output).to include('<td>Name</td><td>Old</td><td>New</td>')
    expect(output).to include('</div>')
  end

  it 'escapes HTML entities' do
    result[:fields] = [{ field: 'Bio', previous_value: '<script>', value: 'safe' }]
    output = described_class.new.call(result)

    expect(output).to include('&lt;script&gt;')
    expect(output).not_to include('<script>')
  end
end
