require File.dirname(__FILE__) + '/spec_helper'

describe EolScenarios do

  describe '.config' do

    it 'should hold configuration settings' do
      EolScenarios.config.should be_a_kind_of(Hash)
      EolScenarios.config.foo = 'bar'

      EolScenarios.config.foo.should   == 'bar'
      EolScenarios.config[:foo].should == 'bar'
      EolScenarios[:foo].should        == 'bar'
      EolScenarios.foo.should          == 'bar'
    end

    it 'should be able to easily reset to default values'

  end

end
