require File.dirname(__FILE__) + '/../../../spec_helper'

describe EOL::LivesHere::Services do

  describe '#self.all' do
    it 'returns an array of available services' do
      EOL::LivesHere::Services.all.should == [:mol]
    end
  end

  describe '#self.get' do
    after(:all){ EOL::LivesHere::Services.instance_variable_set(:@services, {}) }
    it 'instantiates a service only once and always return it' do
       expect(EOL::LivesHere::Services).to receive(:spawn).with(:mol)
         .and_call_original
       expect(EOL::LivesHere::Services.get(:mol))
         .to be_a_kind_of(EOL::LivesHere::Services::Mol)
       expect(EOL::LivesHere::Services).to_not receive(:spawn).with(:mol)
       expect(EOL::LivesHere::Services.get(:mol))
         .to be_a_kind_of(EOL::LivesHere::Services::Mol)
    end
  end
end

