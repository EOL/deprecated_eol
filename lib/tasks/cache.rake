namespace :cache do
  desc 'Clear the cache'
  task :clear do
    Rails.cache.clear
    puts "Cache has been cleared"
  end
end
