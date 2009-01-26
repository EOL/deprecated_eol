require File.dirname(__FILE__) + '/../spec_helper'

describe ContentServer do
  it 'should cycle through the servers on each call to next' do
    old_value = $CONTENT_SERVERS
    $CONTENT_SERVERS = ['a_first', 'b_second', 'c_third', 'd_last'].sort # Should be sorted, but hey.
    called = []
    $CONTENT_SERVERS.length.times do
      called << ContentServer.next
      $CONTENT_SERVERS.include?(called.last).should be_true
    end
    called.sort.should == $CONTENT_SERVERS
    called.include?(ContentServer.next).should be_true # Meaning, we should already have seen the next one!
    $CONTENT_SERVERS = old_value
  end
end
