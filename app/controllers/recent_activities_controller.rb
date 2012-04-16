class RecentActivitiesController < ApplicationController

  layout 'v2/basic'

  def index
    @page_title = I18n.t(:page_title, :scope => [:recent_activities, :index])
    @filter = params[:filter]
    @sort = params[:sort] || 'date_created+desc'
    @log = EOL::ActivityLog.find(self, :filter => @filter, :page => params[:page], :per_page => 50, :sort_by => @sort, :specific_time => "week")
    @rel_canonical_href = recent_activities_url(:page => rel_canonical_href_page_number(@log))
    @rel_prev_href = rel_prev_href_params(@log) ? recent_activities_url(@rel_prev_href_params) : nil
    @rel_next_href = rel_next_href_params(@log) ? recent_activities_url(@rel_next_href_params) : nil
  end

end
