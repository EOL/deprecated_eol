class Communities::NewsfeedsController < CommunitiesController

  def show
    @newsfeed = @community.activity_log(:page => params[:page], :per_page => params[:per_page])
    @rel_canonical_href = community_newsfeed_url(@community, :page => rel_canonical_href_page_number(@newsfeed))
    @rel_prev_href = rel_prev_href_params(@newsfeed) ? community_newsfeed_url(@rel_prev_href_params) : nil
    @rel_next_href = rel_next_href_params(@newsfeed) ? community_newsfeed_url(@rel_next_href_params) : nil
  end

end
