namespace :cache do
  desc 'Clear the cache'
  task :clear => :environment do
    Rails.cache.clear
    puts "Cache has been cleared"
  end
end
