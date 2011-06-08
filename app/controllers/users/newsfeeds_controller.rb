class Users::NewsfeedsController < UsersController

  def show
    @feed_item = FeedItem.new(:feed_id => @user.id, :feed_type => @user.class.name)
  end

end
