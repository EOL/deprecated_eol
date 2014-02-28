require "spec_helper"

describe HierarchiesHelper do

  describe '#en_browsable_status' do

    before do
      @hierarchy = build_stubbed(Hierarchy)
      @hierarchy.stub(:browsable?) { false }
      @hierarchy.stub(:request_publish) { false }
    end

    it 'blank hierarchies are unknown' do
      expect(helper.en_browsable_status(nil)).to eq('unknown')
    end

    it 'browsable hierarchies are browsable' do
      expect(@hierarchy).to receive(:browsable?) { true }
      expect(helper.en_browsable_status(@hierarchy)).to eq('browsable')
    end

    it 'request_publish hierarchies are request_publish' do
      expect(@hierarchy).to receive(:request_publish) { true }
      expect(helper.en_browsable_status(@hierarchy)).to eq('request_publish')
    end

    it 'defaults to not_browsable' do
      expect(helper.en_browsable_status(@hierarchy)).to eq('not_browsable')
    end

  end

end
