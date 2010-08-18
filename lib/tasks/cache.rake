namespace :cache do
  desc 'Clear the cache'
  task :clear do
    $CACHE.clear
    puts "Cache has been cleared"
  end
end
