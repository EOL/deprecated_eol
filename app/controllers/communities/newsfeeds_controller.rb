class Communities::NewsfeedsController < CommunitiesController

  def show
    @feed_item = FeedItem.new_for(:feed => @community, :user => current_user)
  end

end
