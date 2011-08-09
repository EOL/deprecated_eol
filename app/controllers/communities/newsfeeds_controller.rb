class Communities::NewsfeedsController < CommunitiesController

  def show
    @newsfeed = @community.activity_log.paginate(params[:page], params[:per_page])
  end

end
