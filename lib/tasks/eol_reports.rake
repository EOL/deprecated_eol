require 'uri'

namespace :eol_reports do

  desc 'Examine the external links table and produce a simple report called with rake eol_reports:external_links RAILS_ENV=production'
  task :external_links => :environment do

    # sending the EXTRAINFO parameter will append two new nodes to each row, scientific name and page ID, useful for a full listing of valid EOL ids for a partner
    start_date=ENV['STARTDATE'] || '01-01-2009'
    end_date=ENV['ENDDATE'] || Date.today.strftime('%Y-%m-%d')
     
    puts 'Getting external links....'
    logs=ExternalLinkLog.find_by_sql("SELECT * from external_link_logs ORDER BY external_url")
        
    total_logs=logs.size

    puts "Found #{total_logs.to_s} external link logs......"
    puts "Generating report......"
    
    output_location="#{File.dirname(__FILE__)}/../../tmp/"    
    output_file=File.open(output_location + 'external_link_report.csv','w')
    output_file.write "EOL Outlink Click Report,created on #{Time.now.to_s},tracking started ~January 5 2009\n"
    output_file.write "domain,number of outlinks clicked,percent of total\n"
    output_report=[['',0]]
    
    logs.each do |log|
      position=output_report.size-1
      begin 
        parsed_url=URI.parse(log.external_url) 
      rescue
        parsed_url=nil
      end       
        if !parsed_url.nil?
            host=parsed_url.host.downcase 
             if output_report[position][0] == host
              output_report[position][1]+=1
            else
              output_file.write (output_report[position][0] + ',' + output_report[position][1].to_s + ',' + format("%0.2f", (output_report[position][1].to_f/total_logs)*100) + "%\n") if position != 0 
              output_report << [host,1]
            end           
        end
    end

    output_file.close
    puts "Complete - report file created in 'RAILS_ROOT/tmp/'."
        
  end

end


