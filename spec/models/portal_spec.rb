require 'rails_helper'

RSpec.describe Portal do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:categories) }
    it { is_expected.to have_many(:folders) }
    it { is_expected.to have_many(:articles) }
    it { is_expected.to have_many(:inboxes) }
  end

  describe 'validations' do
    let!(:account) { create(:account) }
    let!(:portal) { create(:portal, account_id: account.id) }

    context 'when set portal config' do
      it 'Adds default allowed_locales en' do
        expect(portal.config).to be_present
        expect(portal.config['allowed_locales']).to eq(['en'])
        expect(portal.config['default_locale']).to eq('en')
      end

      it 'Does not allow any other config than allowed_locales' do
        portal.update(config: { 'some_other_key': 'test_value' })
        expect(portal).not_to be_valid
        expect(portal.errors.full_messages[0]).to eq('Cofig in portal on some_other_key is not supported.')
      end

      it 'converts empty string to nil' do
        portal.update(custom_domain: '')
        expect(portal.custom_domain).to be_nil
      end
    end

    context 'when dealing with disabled locales' do
      it 'allows disabled_locales config key' do
        portal.update(config: { 'allowed_locales': %w[en es], 'disabled_locales': ['es'] })
        expect(portal).to be_valid
      end

      it 'prevents disabling the default locale' do
        portal.update(config: { 'allowed_locales': ['en'], 'disabled_locales': ['en'], 'default_locale': 'en' })
        expect(portal).not_to be_valid
        expect(portal.errors[:config]).to include('Default locale cannot be disabled')
      end

      it 'allows disabling non-default locales' do
        portal.update(config: { 'allowed_locales': %w[en es], 'disabled_locales': ['es'], 'default_locale': 'en' })
        expect(portal).to be_valid
      end
    end
  end

  describe 'locale helper methods' do
    let!(:account) { create(:account) }
    let!(:portal) do
      create(:portal, account_id: account.id, config: { 'allowed_locales' => %w[en es fr], 'disabled_locales' => ['es'], 'default_locale' => 'en' })
    end

    describe '#disabled_locales' do
      it 'returns disabled locales from config' do
        expect(portal.disabled_locales).to eq(['es'])
      end

      it 'returns empty array when no disabled locales' do
        portal.update(config: { 'allowed_locales' => ['en'] })
        expect(portal.disabled_locales).to eq([])
      end
    end

    describe '#enabled_locales' do
      it 'returns allowed locales minus disabled locales' do
        expect(portal.enabled_locales).to eq(%w[en fr])
      end
    end

    describe '#locale_enabled?' do
      it 'returns true for default locale regardless of disabled status' do
        expect(portal.locale_enabled?('en')).to be true
      end

      it 'returns false for disabled locales' do
        expect(portal.locale_enabled?('es')).to be false
      end

      it 'returns true for enabled non-default locales' do
        expect(portal.locale_enabled?('fr')).to be true
      end

      it 'returns false for locales not in allowed_locales' do
        expect(portal.locale_enabled?('de')).to be false
      end
    end
  end
end
