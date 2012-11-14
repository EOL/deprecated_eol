class Administrator::StatsController < AdminController

  layout :choose_layout

  before_filter :restrict_to_admins

  def index
    @reports_list = [["--select--",""],
                  ["EOL Web Usage Statistics","http://services.eol.org/eol_php_code/applications/google_stats/index.php"],
                  ["EOL Names Stat","http://services.eol.org/names_stat/"],
                  ["EOL Transfer Schema XML Validator","http://services.eol.org/validator/"],
                  ["UBio-FindIT for URL lists","http://services.eol.org/urls_lookup/"],
                  ]
    @report_url = params[:report_url] || @reports_list[1][1]
    @google_stat_year_list = get_google_stat_year_list
  end

  def SPM_objects_count
    @page_title = I18n.t("species_profile_model_dato_count_title")
    @rec = PageStatsTaxon.latest
    if(@rec["data_objects_count_per_category"] != "[DATA MISSING]" and @rec["data_objects_count_per_category"] != nil) then
      @arr_count = JSON.parse(@rec["data_objects_count_per_category"])
    else
      @arr_count = nil
    end
  end

  def SPM_partners_count
    @page_title = I18n.t("species_profile_model_cp_count_title")
    @rec = PageStatsTaxon.latest
    if(@rec["content_partners_count_per_category"] != "[DATA MISSING]" and @rec["content_partners_count_per_category"] != nil) then
      @arr_count = JSON.parse(@rec["content_partners_count_per_category"])
    else
      @arr_count = nil
    end
  end

  def toc_breakdown
    @page_title = I18n.t("table_of_contents_breakdown_title")
    @all_toc_items = TocItem.find(:all, :include => [ :parent, :info_items ], :order => 'view_order')
  end

  def content_taxonomic
    if params[:hierarchy_id]
      @hierarchy = Hierarchy.find(params[:hierarchy_id])
    else
      @browsable_hierarchies = Hierarchy.browsable_by_label
    end
  end

private

  # Note this runs AFTER the action... so we may already have a @page_title by the time we get here.
  def choose_layout
    @page_title ||= $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
    'left_menu'
  end
  
  def get_google_stat_year_list
    arr=[]
    start="2008_07"
    str=""
    var_date = Time.now
    while( start != str)
      var_date = var_date - 1.month
      str = var_date.year.to_s + "_" + "%02d" % var_date.month.to_s
      arr << var_date.strftime("%Y")
    end
    return arr.uniq
  end
  

end
