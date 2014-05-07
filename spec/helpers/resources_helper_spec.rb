require "spec_helper"

describe ResourcesHelper do

  describe '#frequency' do

    before(:all) do
      Language.create_english
      I18n.locale = Language.english.iso_code
    end

    it 'says "once" when 0' do
      expect(helper.frequency(0)).to match /once/i
    end

    it 'says "weekly" when 7 * 24' do
      expect(helper.frequency(7 * 24)).to match /weekly/i
    end

    it 'says "monthly" when 30 * 24' do
      expect(helper.frequency(30 * 24)).to match /\bmonthly/i
    end

    it 'says "bi-monthly" when 60 * 24' do
      expect(helper.frequency(60 * 24)).to match /bi.?monthly/i
    end

    it 'says "quarterly" when 91 * 24' do
      expect(helper.frequency(91 * 24)).to match /quarterly/i
    end

    it 'counts the hours when weird values' do
      expect(helper.frequency(13)).to match /13 hours/i
      expect(helper.frequency(1)).to match /1 hour\b/i
    end

  end

end
