# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaperTrail::Human::Core::ChangeExtractor do
  subject(:extractor) { described_class.new }

  describe '#call' do
    context 'with JSON object_changes' do
      it 'parses JSON changes' do
        version = instance_double(
          'PaperTrail::Version',
          object_changes: '{"name":["Old","New"],"email":["a@b.com","c@d.com"]}',
          object: nil,
          event: 'update'
        )

        result = extractor.call(version)

        expect(result).to eq('name' => %w[Old New], 'email' => %w[a@b.com c@d.com])
      end
    end

    context 'with YAML object_changes' do
      it 'parses YAML changes' do
        yaml = "---\nname:\n- Old\n- New\n"
        version = instance_double(
          'PaperTrail::Version',
          object_changes: yaml,
          object: nil,
          event: 'update'
        )

        result = extractor.call(version)

        expect(result).to eq('name' => %w[Old New])
      end

      it 'parses YAML with ActiveSupport::TimeWithZone' do
        require 'active_support/core_ext/time/zones'

        yaml = <<~YAML
          ---
          name:
          - Old
          - New
          updated_at:
          - !ruby/object:ActiveSupport::TimeWithZone
            utc: 2026-05-29 12:00:00.000000000 Z
            zone: &1 !ruby/object:ActiveSupport::TimeZone
              name: Etc/UTC
            time: 2026-05-29 12:00:00.000000000 Z
          - !ruby/object:ActiveSupport::TimeWithZone
            utc: 2026-05-29 13:00:00.000000000 Z
            zone: *1
            time: 2026-05-29 13:00:00.000000000 Z
        YAML
        version = instance_double(
          'PaperTrail::Version',
          object_changes: yaml,
          object: nil,
          event: 'update'
        )

        result = extractor.call(version)

        expect(result['name']).to eq(%w[Old New])
        expect(result['updated_at']).to be_an(Array)
      end
    end

    context 'with Hash object_changes (jsonb)' do
      it 'returns hash directly' do
        version = instance_double(
          'PaperTrail::Version',
          object_changes: { 'name' => %w[Old New] },
          object: nil,
          event: 'update'
        )

        result = extractor.call(version)

        expect(result).to eq('name' => %w[Old New])
      end
    end

    context 'without object_changes (create event with object)' do
      it 'infers changes from object for create' do
        version = instance_double(
          'PaperTrail::Version',
          object_changes: nil,
          object: '{"name":"João","email":"j@x.com"}',
          event: 'create'
        )

        result = extractor.call(version)

        expect(result).to eq('name' => [nil, 'João'], 'email' => [nil, 'j@x.com'])
      end
    end

    context 'without object_changes (destroy event with object)' do
      it 'infers changes from object for destroy' do
        version = instance_double(
          'PaperTrail::Version',
          object_changes: nil,
          object: '{"name":"João"}',
          event: 'destroy'
        )

        result = extractor.call(version)

        expect(result).to eq('name' => ['João', nil])
      end
    end

    context 'with no data' do
      it 'returns empty hash' do
        version = instance_double(
          'PaperTrail::Version',
          id: 1,
          object_changes: nil,
          object: nil,
          event: 'update'
        )

        result = extractor.call(version)

        expect(result).to eq({})
      end
    end

    context 'without object_changes on update' do
      it 'emits a warning once' do
        version = instance_double(
          'PaperTrail::Version',
          id: 1,
          object_changes: nil,
          object: nil,
          event: 'update'
        )

        expect { extractor.call(version) }
          .to output(/has no object_changes/).to_stderr
      end
    end
  end
end
