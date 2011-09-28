require File.dirname(__FILE__) + '/../spec_helper'

describe 'Content Partners' do

  before :all do
    load_foundation_cache
  end

  context 'creating' do
    it 'should allow users to create one content partner'
    it 'should allow EOL administrator to create one content partner for a user'
  end

  context 'viewing' do
    it 'should only include public content partners in content partner listings'
    it 'should only allow owners and EOL administrators access to private content partners'
  end

  context 'editing' do
    it 'should allow editing of content partner by owner'
    it 'should restrict fields editable by owner'
    it 'should allow editing of content partner by EOL administrator'
    it 'should provide additional fields editable by EOL administrator'
  end

end

