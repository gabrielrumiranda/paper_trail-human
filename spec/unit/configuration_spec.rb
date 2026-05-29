# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaperTrail::Human::Configuration do
  describe '#register' do
    it 'stores model config' do
      config = described_class.new
      config.register('User') do |m|
        m.field :active, :boolean, true_label: 'Sim', false_label: 'Não'
      end

      model_config = config.config_for('User')

      expect(model_config.fields['active'][:type]).to eq(:boolean)
    end

    it 'freezes model config after registration' do
      config = described_class.new
      config.register('User') do |m|
        m.field :active, :boolean
      end

      model_config = config.config_for('User')

      expect(model_config).to be_frozen
    end
  end

  describe '#ignored_fields' do
    it 'has sensible defaults' do
      config = described_class.new

      expect(config.ignored_fields).to eq(%w[id created_at updated_at])
    end

    it 'allows customization' do
      config = described_class.new
      config.ignored_fields = %i[id slug]

      expect(config.ignored_fields).to eq(%w[id slug])
    end
  end

  describe '#resolve_whodunnit' do
    it 'returns raw id without resolver' do
      config = described_class.new

      expect(config.resolve_whodunnit('42')).to eq('42')
    end

    it 'calls resolver when configured' do
      config = described_class.new
      config.whodunnit_resolver = ->(id) { "User #{id}" }

      expect(config.resolve_whodunnit('42')).to eq('User 42')
    end
  end
end
