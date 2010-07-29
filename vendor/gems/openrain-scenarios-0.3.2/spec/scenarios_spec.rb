require File.dirname(__FILE__) + '/spec_helper'

describe Scenarios do

  describe '.config' do

    it 'should hold configuration settings' do
      Scenarios.config.should be_a_kind_of(Hash)
      Scenarios.config.foo = 'bar'

      Scenarios.config.foo.should   == 'bar'
      Scenarios.config[:foo].should == 'bar'
      Scenarios[:foo].should        == 'bar'
      Scenarios.foo.should          == 'bar'
    end

    it 'should be able to easily reset to default values'

  end

end
