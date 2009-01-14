# Tasks and functions related to the DataObject view logging model.
# Author: Preston Lee <preston.lee@openrain.com>

require 'eol_logging'

include Logging::Mine
include Logging::Mock
      
namespace :logging do

  desc 'Deletes all log entries and derived facts.'
  task :clear => :environment do
    clear_all
  end

  namespace :dimension do

    desc 'Deletes all log entries.'
    task :clear => :environment do
      clear_dimensions
    end

    desc 'Generates realistic-looking-yet-fake log entries for random DataObjects.'
    task :mock => :environment do
      if ENV['THOUSANDS'].nil?
        puts 'You must provide THOUSANDS=<num> as an argument to run this task. <num> should be at least 2.'
        exit 1
      else
        t = ENV['THOUSANDS']
        create_mock_logs(t)
      end
    end
    
  end
  
  namespace :fact do

    desc "Generate all facts for date range, FROM='01/15/2008' TO='01/16/2008'"
    task :range => :environment do
      usage = lambda { puts "Usage:  rake logging:fact FROM='01/15/2008' TO='01/16/2008'"; exit }
      usage.call unless ENV['FROM'] && ENV['TO']
      
      begin
        from, to = Date.parse(ENV['FROM']), Date.parse(ENV['TO'])
      rescue ArgumentError
        puts "Invalid date.  Try something like FROM='12/31/2008'"
        exit
      end

      puts ""
      puts "Generating facts from #{ from.strftime('%m/%d/%Y') } to #{ to.strftime('%m/%d/%Y') }"
      puts ""
      mine_all from..to
    end

    desc 'Clear the entire fact base. DO NOT RUN THIS IN PRODUCTION.'
    task :clear => :environment do
      clear_facts
    end
    
    desc 'Generate all facts for today'
    task :today => :environment do
      mine_all Date.today..Date.today
    end
    
    desc 'Generate all facts for yesterday'
    task :yesterday => :environment do
      mine_all Date.yesterday..Date.yesterday
    end
    
    desc 'Generates all facts for all dimensions.'
    task :all => :environment do
      mine_all
    end

    task :date => :environment do
      raise 'TODO Need to implement this rake task!'     
    end
    
  end

  namespace :geocode do
    
    desc 'Clears all geocoding caches.'
    task :clear => :environment do
      puts "Deleting IP address geocode cache of #{IpAddress.count(:all)} records."
      DataObjectLog.update_all('ip_address_id = NULL')
      IpAddress.delete_all
    end


    desc 'General info about the IP address geocode cache. Provide ADDRESS=<address> for information on a specific record.'
    task :info => :environment do
      puts "Cache contains #{IpAddress.count(:all)} entries."
      if !ENV['ADDRESS'].nil?
        raw = ENV['ADDRESS']
        enc = IpAddress.ip2int
        a = IpAddress.find_by_number(enc)
        if a.nil?
          puts "Address #{raw} not cached!"
        else
          puts "Address #{raw} found! Record dump.."
          pp a
        end
      end
    end
    
    desc 'Runs all pending geocoding tasks, using available caches if available.'
    task :all => :environment do
      geocode_all
    end
    
  end
  
end
