require File.dirname(__FILE__) + '/../spec_helper'

describe Collection, 'with fixtures' do

  fixtures :collections

  before(:each) do
    @fishbase = Collection.find(collections(:fishbase).id)
  end

  it 'should know fishbase as "FishBase species detail"' do
    Collection.fishbase.id.should == @fishbase.id
  end

  it '#ping_host? should be true if FishBase' do
    Collection.should_receive(:fishbase).and_return(@fishbase)
    @fishbase.ping_host?.should be_true
  end

  it '#ping_host_url should return FishBase\'s url, with ID:' do
    @fishbase.ping_host_url.should == 'http://www.fishbase.ca/utility/log/eol/record.php?id=%ID%'
  end

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: collections
#
#  id          :integer(3)      not null, primary key
#  agent_id    :integer(4)      not null
#  description :string(300)     not null
#  link        :string(255)     not null
#  logo_url    :string(255)     not null
#  title       :string(150)     not null
#  uri         :string(255)     not null
#  vetted      :integer(1)      not null

