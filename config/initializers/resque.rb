rails_root = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
rails_env = ENV['RAILS_ENV'] || 'development'

file = rails_root + '/config/resque.yml'
if File.exist?(file)
  puts "** Loading resque config."
  resque_config = YAML.load_file(file)
  Resque.redis = resque_config[rails_env]
end
