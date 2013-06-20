require 'curl'

@app = 446884
@acc = 5035

namespace :relic do

  desc 'Get New Relic stats'
  task :apdex_day => :environment do
    yesterday = (Time.now - 1.day).strftime('%Y-%m-%dT00:00:00Z')
    today = Time.now.strftime('%Y-%m-%dT00:00:00Z')
    response =
      # List of applications (not that we care, just like a ping):
      # Curl::Easy.perform("https://api.newrelic.com/api/v1/accounts/#{@acc}/applications.xml") do |curl| 
      # List of available metrics:
      # Curl::Easy.perform("https://api.newrelic.com/api/v1/applications/#{@app}/metrics.xml") do |curl| 
      #     curl.headers["x-api-key"] = ENV["KEY"]
      # end
      Curl::Easy.perform("https://api.newrelic.com/api/v1/accounts/#{@acc}/applications/#{@app}/data.xml?metrics[]=EndUser/Apdex&field=score&begin=#{yesterday}&end=#{today}") do |curl| 
      curl.headers["x-api-key"] = ENV["KEY"]
    end
    puts response.body_str
  end

end


