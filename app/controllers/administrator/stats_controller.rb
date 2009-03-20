class Administrator::StatsController < AdminController
  
  access_control :DEFAULT => 'Administrator - Site CMS'
  
  def index
    
    @reports_list=[["--select--",""],
                  ["EOL Names Lookup Tool","http://services.eol.org/names_lookup/"],
                  ["EOL Transfer Schema XML Validator","http://services.eol.org/validator/"],
                  ["UBio-FindIT for URL lists","http://services.eol.org/urls_lookup/"],
                  ]
#                  ["Latest Species Page Counts","http://services.eol.org/species_stat/display.php"],
#                  ["General EOL Statistics by lists of names","http://services.eol.org/names_stat/"],
#                  ["Specific EOL Taxa ID Stats","http://services.eol.org/species_stat/index.php"],
    
    @report_url=params[:report_url] || @reports_list[1][1]
    
  end
    
end