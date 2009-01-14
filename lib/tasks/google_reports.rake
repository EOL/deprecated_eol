require 'net/http'
require 'uri'

namespace :google do
  desc 'Export google analytics top pages as CSV'
  task :export do

    # base url to call to get google report
    base_url="https://www.google.com/analytics/reporting/export?"
    parameters="fmt=2&id=6410003&cmp=average&rpt=TopContentReport&tst=0&"
    
    # get parameters
    start_date=ENV['start'] || "2/26/2008"
    end_date=ENV['end'] || "5/5/2008"
    limit=ENV['limit'] || "500"
    
    # convert dates to expected format
    from_date_array=start_date.split("/")
    to_date_array=end_date.split("/") 
    from_year=from_date_array[2]
    from_month=from_date_array[1]
    from_month="0" + from_month if from_month.length==1        
    from_day=from_date_array[0]
    from_day="0" + from_day if from_day.length==1    

    to_year=to_date_array[2]
    to_month=to_date_array[1]
    to_month="0" + to_month if to_month.length==1    
    to_day=to_date_array[0]
    to_day="0" + to_day if to_day.length==1
    
    # append parameters to URL
    parameters+="trows=" + limit
    parameters+="&pdr=" + from_year + from_month + from_day + "-" + to_year + to_month + to_day 
    
   # puts base_url
    resp=Net::HTTP.get_response(URI.parse(base_url + parameters))
    open("output.csv","wb") {|file|
      file.write(resp.body)
    }
  end
end
