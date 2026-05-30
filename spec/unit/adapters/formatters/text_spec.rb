# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaperTrail::Human::Adapters::Formatters::Text do
  let(:result) do
    {
      user: 'John',
      event: 'Updated',
      model: 'User',
      item_id: 1,
      created_at: '2026-05-30 12:00:00',
      fields: [
        { field: 'Name', previous_value: 'Old', value: 'New' },
        { field: 'Email', value: 'new@example.com' }
      ]
    }
  end

  it 'formats as plain text' do
    output = described_class.new.call(result)

    expect(output).to include('Updated User#1 by John')
    expect(output).to include('• Name: Old → New')
    expect(output).to include('• Email: new@example.com')
  end

  it 'handles destroy fields' do
    result[:fields] = [{ field: 'Name', previous_value: 'Old' }]
    output = described_class.new.call(result)

    expect(output).to include('• Name: Old (removed)')
  end
end
