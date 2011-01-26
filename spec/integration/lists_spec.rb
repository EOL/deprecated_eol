require File.dirname(__FILE__) + '/../spec_helper'

describe "Lists controller" do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
  end

  it 'should allow users to like taxa'
  it 'should allow users to like data objects'
  it 'should allow users to like communities'
  it 'should allow users to like lists'
  it 'should allow users to like users'

  it 'should NOT allow users to like themselves.  Kind of oppressive, really.'

  it 'should allow users to add taxa to a specific list'
  it 'should allow users to add data objects to a specific list'
  it 'should allow users to add communities to a specific list'
  it 'should allow users to add lists to a specific list'
  it 'should allow users to add users to a specific list'

  it 'should allow users to add taxa to their task list'
  it 'should allow users to add data objects to their task list'
  it 'should allow users to add communities to their task list'
  it 'should allow users to add lists to their task list'
  it 'should allow users to add users to their task list'

  it 'should allow users to delete specific lists'

  it 'should allow users to edit the name of specific lists'

  it 'should NOT allow users to rename or delete "task" or "like" lists'

  it 'should allow users to create specific lists'

  it 'should allow users with privileges to remove list items'

  it 'should NOT allow users WITHOUT privileges to remove list items'

  describe '#like_dropdown' do

    it 'should show a user\'s specific lists'

    it 'should show a user\'s communities, when they have privileges to add to the community taxa list'

    it 'should NOT show a user\'s communities, when they DON\'T have privileges to add to the community taxa list'

  end

end
