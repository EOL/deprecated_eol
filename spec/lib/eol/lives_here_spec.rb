require File.dirname(__FILE__) + '/../../spec_helper'

RSpec.configure do |config|
  config.include EOL::LivesHere::SpecHelper
end

describe EOL::LivesHere do

  describe '#self.search' do
    let(:latitude){ 123 }
    let(:longitude){ 123 }
    let(:options){ {} }
    before(:each) do
      stub_request_mol
      EOL::LivesHere.config = nil
    end

    context 'with latitude and longitude' do
      it 'searches using configured service' do
        expect_any_instance_of(EOL::LivesHere::Services::Mol)
          .to receive(:search).with(kind_of EOL::LivesHere::Query)
        EOL::LivesHere.search(latitude, longitude, options)
      end
      it 'returns results' do
        expect(EOL::LivesHere.search(latitude, longitude, options))
          .to be_a_kind_of(EOL::LivesHere::Result::Mol)
      end
    end
  end

  describe '#self.config' do
    subject { EOL::LivesHere.config }
    it { expect(subject).to be_a_kind_of(EOL::LivesHere::Configuration) }
  end

  describe EOL::LivesHere::Configuration do

    let(:default_config){ { service: :mol, mol: { radius: 5 } } }
    before(:each){ EOL::LivesHere::Configuration.defaults = default_config }
    let(:custom_config){ { mol: { api_key: 'abc'} } }
    let(:merged_config){ { service: :mol, mol: { radius: 5, api_key: 'abc' } } }

    describe '#self.defaults' do
      it { expect(EOL::LivesHere::Configuration.defaults).to eq(default_config) }
    end

    describe '#self.defaults=' do
      it 'sets defaults' do
        EOL::LivesHere::Configuration.defaults = { service: :custom }
        expect(EOL::LivesHere::Configuration.defaults).to eq({ service: :custom })
      end
    end

    describe '#initialize' do
      subject { EOL::LivesHere::Configuration.new }
      it { expect(subject.configuration).to eq(EOL::LivesHere::Configuration.defaults) }
    end

    describe '#configuration' do
      subject { EOL::LivesHere::Configuration.new }

      context 'without custom configuration' do
        it { expect(subject.configuration).to eq(EOL::LivesHere::Configuration.defaults) }
      end

      context 'with custom configuration' do
        before(:each) { subject.configure(custom_config) }
        it { expect(subject.configuration).to eq(merged_config) }
      end
    end
  end
end


