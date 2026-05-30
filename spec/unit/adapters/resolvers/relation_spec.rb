# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaperTrail::Human::Adapters::Resolvers::Relation do
  describe '#resolve' do
    it 'finds record and returns attribute value' do
      company_class = Class.new do
        def self.find_by(id:)
          return Struct.new(:name).new('Acme Corp') if id == 1

          nil
        end
      end
      stub_const('Company', company_class)

      resolver = described_class.new(class_name: 'Company', attribute: :name)

      expect(resolver.resolve(1)).to eq('Acme Corp')
    end

    it 'returns raw value when record not found' do
      company_class = Class.new do
        def self.find_by(id:)
          nil
        end
      end
      stub_const('Company', company_class)

      resolver = described_class.new(class_name: 'Company', attribute: :name)

      expect(resolver.resolve(999)).to eq(999)
    end

    it 'returns raw value when class does not exist' do
      resolver = described_class.new(class_name: 'NonExistentModel', attribute: :name)

      expect(resolver.resolve(1)).to eq(1)
    end
  end
end
