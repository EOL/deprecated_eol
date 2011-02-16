require File.dirname(__FILE__) + '/../spec_helper'

describe SpecialCollection do

  before(:all) do
    SpecialCollection.create_all
  end

  it 'should have a "focus" method' do
    SpecialCollection.focus.should_not be_nil
  end

  it 'should have a "inbox" method' do
    SpecialCollection.inbox.should_not be_nil
  end

  it 'should have a "watch" method' do
    SpecialCollection.watch.should_not be_nil
  end

  it 'should have a "task" method' do
    SpecialCollection.task.should_not be_nil
  end

end
