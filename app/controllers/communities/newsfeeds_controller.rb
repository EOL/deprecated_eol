class Communities::NewsfeedsController < CommunitiesController

  def show
    @newsfeed = @community.activity_log(:page => params[:page], :per_page => params[:per_page])
  end

end
