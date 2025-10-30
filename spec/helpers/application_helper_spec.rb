require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#format_ssn' do
    let!(:setting) { Setting.create!(key: 'last_four_ssn', value: true) }

    context 'when last_four_ssn setting is enabled' do
      it 'masks SSN showing only last 4 digits' do
        expect(helper.format_ssn('123-45-6789')).to eq('***-**-6789')
      end

      it 'handles SSN without dashes' do
        expect(helper.format_ssn('123456789')).to eq('***-**-6789')
      end
    end

    context 'when last_four_ssn setting is disabled' do
      before { setting.update!(value: false) }

      it 'returns full SSN' do
        expect(helper.format_ssn('123-45-6789')).to eq('123-45-6789')
      end
    end

    context 'when SSN is nil or empty' do
      it 'returns empty string for nil' do
        expect(helper.format_ssn(nil)).to eq('')
      end

      it 'returns empty string for empty string' do
        expect(helper.format_ssn('')).to eq('')
      end
    end

    context 'when setting does not exist' do
      before { setting.destroy }

      it 'returns full SSN as fallback' do
        expect(helper.format_ssn('123-45-6789')).to eq('123-45-6789')
      end
    end
  end
end
