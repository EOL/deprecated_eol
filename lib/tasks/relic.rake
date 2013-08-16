# require 'curl'
# 
# @app = 446884
# @acc = 5035
# 
# def curl_it(options)
#   response =
#     Curl::Easy.perform("https://api.newrelic.com/api/v1/#{options[:acc] ? "accounts/#{@acc}" : ''}/#{options[:app] ? "applications/#{@app}" : ''}/#{options[:cmd]}") do |curl|
#       curl.headers["x-api-key"] = ENV["KEY"]
#     end
#   puts response.body_str
# end
# 
# namespace :relic do
# 
#   # Curl::Easy.perform("https://api.newrelic.com/api/v1/accounts/#{@acc}/applications.xml") do |curl|
#   desc 'List of applications available... akin to a ping'
#   task :apps do
#     curl_it(acc: true, cmd: 'applications.xml')
#   end
# 
#   desc 'Get New Relic\'s list of available metrics'
#   task :metrics => :environment do
#     curl_it(app: true, cmd: 'metrics.xml')
#   end
# 
#   desc 'Get New Relic apdex scores (per hour) for the past day'
#   task :apdex_day => :environment do
#     yesterday = (Time.now - 1.day).strftime('%Y-%m-%dT00:00:00Z')
#     today = Time.now.strftime('%Y-%m-%dT00:00:00Z')
#     curl_it(acc: true, app: true, cmd: "data.xml?metrics[]=EndUser/Apdex&field=score&begin=#{yesterday}&end=#{today}")
#   end
# 
# end
# 
# 
