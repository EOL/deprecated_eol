class Administrator::StatsController < AdminController

  layout :choose_layout
  

  access_control :DEFAULT => 'Administrator - Usage Reports'
  
  def index        
    @reports_list=[["--select--",""],
                  ["Latest Species Page Counts","http://services.eol.org/species_stat/display.php"],
                  ["EOL Web Usage Statistics","http://services.eol.org/eol_php_code/applications/google_stats/index.php"],                  
                  ["EOL Data Objects by Partner","http://services.eol.org/eol_php_code/applications/partner_stat/index.php"],                  
                  ["EOL Names Lookup Tool","http://services.eol.org/names_lookup/"],
                  ["EOL Transfer Schema XML Validator","http://services.eol.org/validator/"],
                  ["UBio-FindIT for URL lists","http://services.eol.org/urls_lookup/"],
                  ["General EOL Statistics by lists of names","http://services.eol.org/names_stat/"],
                  ["EOL Resource Monitoring - RSS Feeds","http://services.eol.org/RSS_resource_monitor/"]
                  ]
#                  ["Specific EOL Taxa ID Stats","http://services.eol.org/species_stat/index.php"],
    
    @report_url=params[:report_url] || @reports_list[1][1]
    
  end
  
  def SPM_objects_count
    @page_title = 'Species Profile Model - Data Objects Count'
    @arr_SPM = InfoItem.get_schema_value        
    @rec = PageStatsTaxon.latest    
    if(@rec["data_objects_count_per_category"] != "[DATA MISSING]" and @rec["data_objects_count_per_category"] != nil) then
      @arr_count = JSON.parse(@rec["data_objects_count_per_category"])      
    else
      @arr_count = nil
    end
    #@arr_count = DataObject.get_SPM_count_on_dataobjects(@arr_SPM)    
    #add numbers from User Submitted Text - UsersDataObjects table
    #@arr_user_object_ids = UsersDataObject.get_all_object_ids  
    #@arr_count = DataObject.add_user_dataobjects_on_SPM_count(@arr_count, @arr_user_object_ids)
  end

  def SPM_partners_count
    @page_title = 'Species Profile Model - Content Partners Count'
    @arr_SPM = InfoItem.get_schema_value    
    @rec = PageStatsTaxon.latest
    if(@rec["content_partners_count_per_category"] != "[DATA MISSING]" and @rec["content_partners_count_per_category"] != nil) then
      @arr_count = JSON.parse(@rec["content_partners_count_per_category"])
    else
      @arr_count = nil
    end
    #@arr_count = DataObject.get_SPM_count_on_contentpartners(@arr_SPM)
  end

  def toc_breakdown
    @page_title = 'Table of Contents Breakdown'
    @arr_toc = InfoItem.get_toc_breakdown
  end
  
  def content_taxonomic
    if params[:hierarchy_id]
      @hierarchy = Hierarchy.find(params[:hierarchy_id])
    else
      @browsable_hierarchies = Hierarchy.browsable_by_label
    end
  end
  
  
  private
  def choose_layout
    action_name == 'content_taxonomic' ? 'admin' : 'admin_without_nav'
  end
end
