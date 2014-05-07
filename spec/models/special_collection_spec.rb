require "spec_helper"

describe SpecialCollection do

  before(:all) do
    SpecialCollection.create_enumerated
  end

  it 'should have a "focus" method' do
    SpecialCollection.focus.should_not be_nil
  end

  it 'should have a "watch" method' do
    SpecialCollection.watch.should_not be_nil
  end

end
