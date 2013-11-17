require File.dirname(__FILE__) + '/../spec_helper'

describe Enumerated do

  it 'should handle the most basic translated enumerated class' do
    ViewStyle.delete_all
    TranslatedViewStyle.delete_all
    ViewStyle.create_enumerated
    ViewStyle.enumerations.each do |enum, val|
      expect(ViewStyle.send(enum).name).to eq(val)
    end
  end

end
