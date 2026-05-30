# frozen_string_literal: true

require 'spec_helper'
require 'i18n'

RSpec.describe PaperTrail::Human::Core::EventTranslator do
  before do
    I18n.available_locales = %i[en pt-BR]
    I18n.locale = :en
    I18n.backend.store_translations(:en, paper_trail_human: { events: {
                                      create: 'Created',
                                      update: 'Updated',
                                      destroy: 'Destroyed'
                                    } })
    I18n.backend.store_translations(:'pt-BR', paper_trail_human: { events: {
                                      create: 'Criação',
                                      update: 'Atualização',
                                      destroy: 'Exclusão'
                                    } })
  end

  describe '.call' do
    context 'when translate is false' do
      it 'returns raw event string' do
        expect(described_class.call('create', translate: false)).to eq('create')
      end
    end

    context 'when translate is true (English)' do
      it 'returns translated labels' do
        expect(described_class.call('create', translate: true)).to eq('Created')
        expect(described_class.call('update', translate: true)).to eq('Updated')
        expect(described_class.call('destroy', translate: true)).to eq('Destroyed')
      end
    end

    context 'when translate is true (pt-BR)' do
      before { I18n.locale = :'pt-BR' }

      after { I18n.locale = :en }

      it 'returns translated labels' do
        expect(described_class.call('create', translate: true)).to eq('Criação')
        expect(described_class.call('update', translate: true)).to eq('Atualização')
        expect(described_class.call('destroy', translate: true)).to eq('Exclusão')
      end
    end

    context 'with unknown event' do
      it 'returns the raw event' do
        expect(described_class.call('archive', translate: true)).to eq('archive')
      end
    end
  end
end
