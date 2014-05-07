class Communities::NewsfeedsController < CommunitiesController

  def show
    @newsfeed = @community.activity_log(page: params[:page], per_page: params[:per_page], user: current_user)
    set_canonical_urls(for: @community, paginated: @newsfeed, url_method: :community_newsfeed_url)
  end

end
