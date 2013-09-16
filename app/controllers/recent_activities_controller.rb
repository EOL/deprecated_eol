class RecentActivitiesController < ApplicationController

  layout 'v2/basic'

  def index
    @page_title = I18n.t(:page_title, :scope => [:recent_activities, :index])
    @filter = params[:filter]
    @sort = params[:sort] || 'date_created+desc'
    @log = EOL::ActivityLog.find(self, :filter => @filter, :page => params[:page], :per_page => 50, :sort_by => @sort, :recent_days => 7, :user => current_user)
    set_canonical_urls(:paginated => @log, :url_method => :recent_activities_url)
  end

end
