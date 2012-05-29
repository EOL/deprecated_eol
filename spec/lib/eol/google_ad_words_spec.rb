require File.dirname(__FILE__) + '/../../spec_helper'

describe EOL::GoogleAdWords do

  describe '#self.create_signup_conversion' do
    it 'should create an EOL::GoogleAdWords::Conversion instance with default values' do
      conversion = EOL::GoogleAdWords.create_signup_conversion
      conversion.should be_a(EOL::GoogleAdWords::Conversion)
      conversion.id.should be_a(Integer)
      conversion.label.should be_a(String)
      conversion.value.should be_a(Integer)
    end
  end

end
