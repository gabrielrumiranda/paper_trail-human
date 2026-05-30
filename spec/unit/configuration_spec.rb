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

  describe '#resolve_item_name' do
    let(:version) do
      instance_double('PaperTrail::Version', item_type: 'User', item_id: 1)
    end

    it 'returns nil when no item_name configured' do
      config = described_class.new

      expect(config.resolve_item_name(version)).to be_nil
    end

    it 'resolves via attribute on the model' do
      user_class = Class.new do
        def self.find_by(id:)
          new(id)
        end

        def initialize(id)
          @id = id
        end

        def name
          'João Silva'
        end
      end
      stub_const('User', user_class)

      config = described_class.new
      config.register('User') { |m| m.item_name :name }

      expect(config.resolve_item_name(version)).to eq('João Silva')
    end

    it 'resolves via lambda' do
      config = described_class.new
      config.register('User') { |m| m.item_name ->(v) { "Item ##{v.item_id}" } }

      expect(config.resolve_item_name(version)).to eq('Item #1')
    end

    it 'returns nil when record not found' do
      user_class = Class.new do
        def self.find_by(id:)
          nil
        end
      end
      stub_const('User', user_class)

      config = described_class.new
      config.register('User') { |m| m.item_name :name }

      expect(config.resolve_item_name(version)).to be_nil
    end
  end
end
