class Administrator::SiteController  < AdminController
  
  access_control :DEFAULT => 'Administrator - Technical'
  
  def index
    @taxon_stats=TaxonStat.find(:all,:limit=>1,:order=>'created_at DESC')
    @allowed_ip=allowed_request
    @config = Rails::Configuration.new
  end

  def surveys

    @surveys=SurveyResponse.paginate(:order=>'created_at desc',:page => params[:page])
    @all_surveys_count=SurveyResponse.count
    @no_surveys_count=SurveyResponse.count(:conditions=>['user_response=?','no'])
    @yes_surveys_count=SurveyResponse.count(:conditions=>['user_response=?','yes'])
    @done_surveys_count=SurveyResponse.count(:conditions=>['user_response=?','done'])

  end

  # AJAX method to expire all non-species pages
  def clear_all
    
    unless request.xhr?
      render :nothing=>true
      return 
    end
    if clear_all_caches
      message='All caches cleared on ' + format_date_time(Time.now)
    else
      message='Caches could not be cleared'
    end    
    render :text=>message,:layout=>false
  end
    
  # AJAX method to expire all non-species pages
  def expire_all
    
    unless request.xhr?
      render :nothing=>true
      return 
    end
    expire_caches
    message='Non-species page caches cleared on ' + format_date_time($CACHE_CLEARED_LAST)
    render :text=>message,:layout=>false
  end

  # AJAX method to expire all non-species pages
  def expire

    taxon_id=params[:taxon_id]
    unless request.xhr? && !taxon_id.blank?
      render :nothing=>true
      return 
    end
    if expire_taxon(taxon_id)
      message='Taxon ID ' + taxon_id + ' was expired on ' + format_date_time(Time.now) + '<br />'
    else
      message='Taxon ID ' + taxon_id + ' could not be expired<br />'
    end
    render :text=>message,:layout=>false
    
  end
    
end