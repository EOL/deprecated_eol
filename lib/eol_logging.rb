# Toolkit for common logging-related code.
#
# Author: Preston Lee <preston.lee@openrain.com>
module Logging
  
  module Mine
    
    def delete_all_records(models)
      models.each do |n|
        puts "Deleting #{n.count(:all)} #{n} records."
        n.delete_all
      end
    end
    
    def clear_dimensions
      delete_all_records [::DataObjectLog, ::IpAddress]
    end
    
    def clear_facts
      delete_all_records ::LogDaily.report_classes
    end

    def clear_all
      clear_dimensions
      clear_facts
    end
    
    def mine_all date_range = nil
      ::LogDaily.report_classes.each do |klass|
        puts "Mining #{klass.path} for range: #{ date_range.inspect }"
        total, mined, skipped = klass.mine date_range
        puts "  #{mined} mined and #{skipped} skipped out of #{total}"
      end
    end
    
    def mine_range date_range = nil
      mine_all date_range
    end
    
    def geocode_all
      # FOR ERROR LOGGING
      num_logs_that_didnt_save  = 0
      first_log_that_didnt_save = nil

      chunk_size = 200
      require 'geo_kit/geocoders'
      include GeoKit::Geocoders
      
      size = ::DataObjectLog.count(:all, :conditions => ['ip_address_id IS NULL'])
      puts "Geocoding approximately #{size} log entries."
      while (logs = ::DataObjectLog.find(:all, :conditions => ['ip_address_id IS NULL'], :limit => chunk_size)).size > 0 do
        puts "Performing IP lookup for a #{logs.size} record chunk. (Some/All may be from cache.)"
        ::DataObjectLog.transaction do
          logs.each do |log|
            addr = ::IpAddress.find_by_number(log.ip_address_raw)
            if addr.nil?
              # We need to perform a lookup, cache the result and associated the entry.      
              ip_str = IpAddress.int2ip(log.ip_address_raw)
              puts "Cache miss for #{ip_str}."
              result = IpGeocoder.geocode(ip_str)
              addr = IpAddress.new
              addr.number = log.ip_address_raw
              addr.success = result.success
              
              addr.street_address = result.street_address
              addr.city = result.city
              addr.state = result.state
              addr.postal_code = result.zip
              addr.country_code = result.country_code
              addr.latitude = result.lat
              addr.longitude = result.lng
              addr.provider = result.provider
              addr.precision = result.precision
              
              addr.save!

            else
              # We can use the cached result!
              log.ip_address = addr

              begin
                log.save!
              rescue Exception => ex
                # for now, we need to deal with the fact that this is 
                # getting production errors and just not save the log, 
                # if there's an error
                #
                # we will figure out why some logs aren't working, in the future
                #
                # if most logs are coming through, that's what we really need!
                #
                # for now, eat errors here
                #
                num_logs_that_didnt_save += 1
                first_log_that_didnt_save = log unless first_log_that_didnt_save
              end

            end
          end
        end
      end

      if num_logs_that_didnt_save > 0
        message = "#{ num_logs_that_didnt_save } logs threw errors while " + 
                  "attempting to be saved!  the first log: #{ first_log_that_didnt_save.inspect }"
        Rails.logger.error message
        Rails.logger.flush # commit anything logged to the actual log file
                                   # as Rails doen't enable auto_flushing in production mode
      end
    end
    
  end
  
end
