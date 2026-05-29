# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Thread safety' do
  it 'handles concurrent configuration reads safely' do
    PaperTrail::Human.configure do |config|
      config.register('User') do |m|
        m.field :active, :boolean, true_label: 'Sim', false_label: 'Não'
      end
    end

    version = instance_double(
      'PaperTrail::Version',
      item_type: 'User', item_id: 1, event: 'update', whodunnit: nil,
      created_at: Time.now, object_changes: { 'active' => [true, false] }, object: nil
    )

    threads = Array.new(10) do
      Thread.new { PaperTrail::Human.format(version) }
    end

    results = threads.map(&:value)

    results.each do |result|
      expect(result[:fields].first[:previous_value]).to eq('Sim')
      expect(result[:fields].first[:value]).to eq('Não')
    end
  end
end
