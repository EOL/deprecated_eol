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
              log.save!
            end
          end
        end
      end
    end
    
  end
  
  module Mock
    
    # TODO randomize all fields (currently ignoring agent_id, user_id, ...)
    #
    #
    def create_mock_logs(count)
      if count.to_i < 2
        raise 'THOUSANDS must be at least 2.'
      end
      
      puts "Generating #{count} thousand log entries."
      agents = [
        'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-GB; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6', 
        'Opera/9.20 (Windows NT 6.0; U; en)',
        'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)',
        'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; .NET CLR 1.1.4322)'
        ]
      agent_ids = [ 2, 25 ] # these are the ids of Agent objects that have actual logins, so we can test with them
    
      (1..count.to_i).each do
        ::DataObjectLog.transaction do
          for n in 1..1000 do
            addr = "4.#{n % 10}.2.1"
            agent = agents[n % agents.size]
            attribute_hash[:ip_address_raw] = ::IpAddress.ip2int addr
            attribute_hash[:user_agent] = agent
            attribute_hash[:agent_id] = agent_ids[n % agent_ids.size]
            attribute_hash[:created_at] = (n * 15).minutes.ago
            # TODO Make this database agnostic.
            obj = ::DataObject.find(:first, :include => [:data_type], :conditions => [''], :order => 'RAND()', :limit => 1)
            attribute_hash[:data_object] = obj
            attribute_hash[:data_type] = obj.data_type
            if 0 == n % 4
              attribute_hash[:user_id] = User.find_by_sql('SELECT id FROM users ORDER BY RAND() LIMIT 1')
            end
            ::DataObjectLog.create(attribute_hash)
          end
        end
      end
    
    end

  end

end
