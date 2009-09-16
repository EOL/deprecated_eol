class Administrator::StatsController < AdminController
  
  access_control :DEFAULT => 'Administrator - Usage Reports'
  
  def index
    
    @reports_list=[["--select--",""],
                  ["Latest Species Page Counts","http://services.eol.org/species_stat/display.php"],
                  ["EOL Web Usage Statistics","http://services.eol.org/eol_php_code/applications/google_stats/index.php"],                  
                  ["EOL Names Lookup Tool","http://services.eol.org/names_lookup/"],
                  ["EOL Transfer Schema XML Validator","http://services.eol.org/validator/"],
                  ["UBio-FindIT for URL lists","http://services.eol.org/urls_lookup/"],
                  ["General EOL Statistics by lists of names","http://services.eol.org/names_stat/"]]
#                  ["Specific EOL Taxa ID Stats","http://services.eol.org/species_stat/index.php"],
    
    @report_url=params[:report_url] || @reports_list[1][1]
    
  end
    
end