class RecentActivitiesController < ApplicationController

  layout 'v2/activities'

  def index
    @filter = params[:filter]
    @sort = params[:sort] || 'date_created+desc'
    @log = EOL::ActivityLog.find(self, :filter => @filter, :page => params[:page], :per_page => 50, :sort_by => @sort, :specific_time => "week")
  end

protected

  def meta_title
    return @meta_title if defined?(@meta_title)
    @meta_title = I18n.t(:recent_eol_member_activity)
  end

  def meta_keywords
    return @meta_keywords if defined?(@meta_keywords)
    @meta_keywords = [I18n.t(:eol_activity), 
                I18n.t(:eol_recent_member_activity), 
                I18n.t(:eol_recent_member_activities), 
                I18n.t(:eol_activities), 
                I18n.t(:eol_community_activity), 
                I18n.t(:eol_recent_activity)     ].uniq.compact.join(", ")
  end

end
