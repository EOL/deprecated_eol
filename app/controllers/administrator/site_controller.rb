class Administrator::SiteController  < AdminController

  layout 'deprecated/left_menu'

  before_filter :set_layout_variables

  helper :resources

  before_filter :restrict_to_admins

  def index
    @page_title = 'General Site Administration'
    @allowed_ip = allowed_request
    @config = Eol::Application.config
  end

  def surveys
    @page_title = 'Survey Respondents'
    @surveys = SurveyResponse.paginate(:order => 'created_at desc', :page => params[:page])
    @all_surveys_count  = SurveyResponse.count
    @no_surveys_count   = SurveyResponse.count(:conditions => ['user_response = ?','no'])
    @yes_surveys_count  = SurveyResponse.count(:conditions => ['user_response = ?','yes'])
    @done_surveys_count = SurveyResponse.count(:conditions => ['user_response = ?','done'])
  end

  # AJAX method to expire all non-species pages
  def clear_all
    unless request.xhr?
      render :nothing => true
      return
    end
    if clear_all_caches
      message = 'All caches cleared on ' + view_helper_methods.format_date_time(Time.now)
    else
      message = 'Caches could not be cleared'
    end
    render :text => message, :layout => false
  end

  # AJAX method to expire all non-species pages
  def expire_all
    unless request.xhr?
      render :nothing => true
      return
    end
    expire_non_species_caches
    message = 'Non-species page caches cleared on ' + view_helper_methods.format_date_time($CACHE_CLEARED_LAST)
    render :text => message, :layout => false
  end

  # AJAX method to expire all non-species pages
  def expire
    taxon_concept_id = params[:taxon_id]
    unless request.xhr? && !taxon_concept_id.blank?
      render :nothing => true
      return
    end
    message = '' # Scope.
    begin
      expire_taxa([taxon_concept_id])
      message = "Taxon ID #{taxon_concept_id} was expired on #{view_helper_methods.format_date_time(Time.now)}<br />"
    rescue => e
      message = "Taxon ID #{taxon_concept_id} could not be expired: #{e.message}<br />"
    end
    render :text => message, :layout => false
  end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
