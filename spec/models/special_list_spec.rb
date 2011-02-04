require File.dirname(__FILE__) + '/../spec_helper'

describe SpecialList do

  before(:all) do
    SpecialList.create_all
  end

  it 'should have a "taxa" method' do
    SpecialList.taxa.should_not be_nil
  end

  it 'should have a "like" method' do
    SpecialList.like.should_not be_nil
  end

  it 'should have a "task" method' do
    SpecialList.task.should_not be_nil
  end

end
