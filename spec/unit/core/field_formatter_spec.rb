# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaperTrail::Human::Core::FieldFormatter do
  describe '#call' do
    context 'without model config' do
      it 'returns raw values with humanized field name' do
        formatter = described_class.new(nil, 'NonExistentModel')

        result = formatter.call('first_name', 'Old', 'New')

        expect(result).to eq(field: 'First name', previous_value: 'Old', value: 'New')
      end

      it 'strips _id suffix from field name' do
        formatter = described_class.new(nil, 'NonExistentModel')

        result = formatter.call('company_id', 1, 2)

        expect(result[:field]).to eq('Company')
      end
    end

    context 'with boolean resolver config' do
      it 'resolves boolean values' do
        model_config = PaperTrail::Human::ModelConfig.new
        model_config.field(:active, :boolean, true_label: 'Ativo', false_label: 'Inativo')
        model_config.freeze

        formatter = described_class.new(model_config, 'SomeModel')

        result = formatter.call('active', true, false)

        expect(result[:previous_value]).to eq('Ativo')
        expect(result[:value]).to eq('Inativo')
      end
    end

    context 'with custom resolver config' do
      it 'applies custom lambda' do
        model_config = PaperTrail::Human::ModelConfig.new
        model_config.field(:score, :custom, resolve: ->(v) { "#{v} pontos" })
        model_config.freeze

        formatter = described_class.new(model_config, 'SomeModel')

        result = formatter.call('score', 10, 20)

        expect(result[:previous_value]).to eq('10 pontos')
        expect(result[:value]).to eq('20 pontos')
      end
    end

    context 'with nil values' do
      it 'does not resolve nil' do
        model_config = PaperTrail::Human::ModelConfig.new
        model_config.field(:score, :custom, resolve: ->(v) { "#{v} pontos" })
        model_config.freeze

        formatter = described_class.new(model_config, 'SomeModel')

        result = formatter.call('score', nil, 20)

        expect(result[:previous_value]).to be_nil
        expect(result[:value]).to eq('20 pontos')
      end
    end

    context 'with invalid resolver type' do
      it 'raises Error' do
        model_config = PaperTrail::Human::ModelConfig.new
        model_config.field(:name, :invalid_type)
        model_config.freeze

        formatter = described_class.new(model_config, 'SomeModel')

        expect { formatter.call('name', 'Old', 'New') }
          .to raise_error(PaperTrail::Human::Error, /Unknown resolver type/)
      end
    end
  end
end
