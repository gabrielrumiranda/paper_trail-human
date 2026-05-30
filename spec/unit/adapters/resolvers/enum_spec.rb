# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaperTrail::Human::Adapters::Resolvers::Enum do
  describe '#resolve' do
    context 'with mapping hash' do
      it 'resolves value from mapping' do
        resolver = described_class.new(mapping: { 'admin' => 'Administrador', 'user' => 'Usuário' })

        expect(resolver.resolve('admin')).to eq('Administrador')
      end

      it 'returns raw value when not in mapping' do
        resolver = described_class.new(mapping: { 'admin' => 'Administrador' })

        expect(resolver.resolve('unknown')).to eq('unknown')
      end
    end

    context 'with class and method' do
      it 'calls method on class' do
        enum_class = Class.new do
          def self.label(value)
            { 'admin' => 'Administrador' }[value]
          end
        end
        stub_const('UserRole', enum_class)

        resolver = described_class.new(class_name: 'UserRole', method: :label)

        expect(resolver.resolve('admin')).to eq('Administrador')
      end

      it 'returns raw value when method returns nil' do
        enum_class = Class.new do
          def self.label(_value)
            nil
          end
        end
        stub_const('UserRole', enum_class)

        resolver = described_class.new(class_name: 'UserRole', method: :label)

        expect(resolver.resolve('unknown')).to eq('unknown')
      end

      it 'returns raw value when class does not exist' do
        resolver = described_class.new(class_name: 'NonExistentEnum', method: :label)

        expect(resolver.resolve('admin')).to eq('admin')
      end
    end

    context 'with from_model (Rails enum)' do
      before do
        model_class = Class.new do
          def self.defined_enums
            { 'role' => { 'admin' => 0, 'editor' => 1, 'viewer' => 2 } }
          end
        end
        stub_const('User', model_class)
      end

      it 'resolves integer value to humanized key' do
        resolver = described_class.new(from_model: 'User', field: 'role')

        expect(resolver.resolve(0)).to eq('Admin')
        expect(resolver.resolve(1)).to eq('Editor')
        expect(resolver.resolve(2)).to eq('Viewer')
      end

      it 'uses custom labels when provided' do
        resolver = described_class.new(from_model: 'User', field: 'role',
                                       labels: { admin: 'Administrador', editor: 'Editor', viewer: 'Leitor' })

        expect(resolver.resolve(0)).to eq('Administrador')
        expect(resolver.resolve(2)).to eq('Leitor')
      end

      it 'returns raw value when enum not found' do
        resolver = described_class.new(from_model: 'User', field: 'status')

        expect(resolver.resolve(0)).to eq(0)
      end
    end
  end
end
