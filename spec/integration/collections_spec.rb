require File.dirname(__FILE__) + '/../spec_helper'

describe "Collections controller" do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
  end

  it 'should allow users to like taxa'
  it 'should allow users to like data objects'
  it 'should allow users to like communities'
  it 'should allow users to like collections'
  it 'should allow users to like users'

  it 'should NOT allow users to like themselves.  Kind of oppressive, really.'

  it 'should allow users to add taxa to a specific collection'
  it 'should allow users to add data objects to a specific collection'
  it 'should allow users to add communities to a specific collection'
  it 'should allow users to add collections to a specific collection'
  it 'should allow users to add users to a specific collection'

  it 'should allow users to add taxa to their task collection'
  it 'should allow users to add data objects to their task collection'
  it 'should allow users to add communities to their task collection'
  it 'should allow users to add collections to their task collection'
  it 'should allow users to add users to their task collection'

  it 'should allow users to delete specific collections'

  it 'should allow users to edit the name of specific collections'

  it 'should NOT allow users to rename or delete "task" or "like" collections'

  it 'should allow users to create specific collections'

  it 'should allow users with privileges to remove collection items'

  it 'should NOT allow users WITHOUT privileges to remove collection items'

  describe '#like_dropdown' do

    it 'should show a user\'s specific collections'

    it 'should show a user\'s communities, when they have privileges to add to the community focus'

    it 'should NOT show a user\'s communities, when they DON\'T have privileges to add to the community focus'

  end

end
