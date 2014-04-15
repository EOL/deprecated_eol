require "spec_helper"

describe PageStatsTaxon do

  describe '.latest' do

    before do
      PageStatsTaxon.delete_all
    end

    it 'returns the latest' do
      @old = PageStatsTaxon.create(date_created: 1.day.ago)
      @new = PageStatsTaxon.create(date_created: 1.minute.ago)
      expect(PageStatsTaxon.latest).to eq(@new)
    end

    it 'returns nothing if none' do
      expect(PageStatsTaxon.latest).to_not be_a(PageStatsTaxon)
    end

  end

end
