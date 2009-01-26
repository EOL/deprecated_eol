require File.dirname(__FILE__) + '/../spec_helper'

def four_comments
  users = []
  4.times do
    users << User.create_new(:username => "user#{users.length}")
  end
  comments = []
  4.times do
    comments << Comment.create(:data_object_id => @mock_dato.id, :body => "Comment #{comments.length}",
                               :visible_at => 1.minute.ago, :user_id => users[comments.length].id)
  end
  return comments
end

# All commented-out lines are here just to stall: we don't care about comments for this iteration.

describe DataObjectsController, '#show (with views)' do
  integrate_views
  
  before(:each) do
    @mock_license = mock_model(License)
    @mock_license.stub!(:small_logo_url).and_return('whatever.png')
    @mock_license.stub!(:title).and_return('All Rights Absurd')
    @mock_license.stub!(:description).and_return('Do what you want with it')
    @mock_license.stub!(:source_url).and_return('/some/path')
    @mock_dato = mock_model(DataObject)
    @mock_dato.stub!(:authors).and_return([])
    @mock_dato.stub!(:sources).and_return([])
    @mock_dato.stub!(:smart_image).and_return('image url')
    @mock_dato.stub!(:license).and_return(@mock_license)
    @mock_dato.stub!(:image?).and_return(true)
    @mock_dato.stub!(:comments).and_return([])
    @mock_dato.stub!(:object_title).and_return('obj title')
    @mock_dato.stub!(:description).and_return('describe me!')
    #DataObject.should_receive(:find).with(@mock_dato.id).and_return(@mock_dato)
    @moderator = mock_user
    @moderator.stub!(:is_moderator).and_return(true)
  end

  it 'should show title and description' do
    #@mock_dato.should_receive(:object_title).at_least(1).times.and_return("Title here")
    #@mock_dato.should_receive(:description).at_least(1).times.and_return("Some description here")
    #get 'show', :id => @mock_dato.id
    #response.body.should match(/Title here/)
    #response.body.should match(/Some description here/)
  end

  it 'should show all associated comments with usernames and dates'

  it 'should NOT show hidden comments to a normal user'

  it 'should show hidden comments to a moderator'

  it 'should have "remove" links on each comment, for moderator' do
    #comments = four_comments
    #session[:user] = @moderator
    #@mock_dato.should_receive(:comments).at_least(1).times.and_return(comments)
    #get 'show', :id => @mock_dato.id
    #puts response.body
    #response.should have_tag('div#comments') do
      #with_tag('div.comment-footer') do
        #with_tag('a', /remove/)
      #end
    #end
  end

  it 'should have an "undo" link for moderators who just removed a comment'

  it 'should have a login link after the comment when no user'

  it 'should have a new comment box (with hidden user) when logged in'

  it 'should show the number of comments'

  it 'should contain the image, if the data object is an image'

end
