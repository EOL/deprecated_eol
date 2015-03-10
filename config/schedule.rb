set :output, {:error => "log/cron_error_log.log", :standard => "log/cron_log.log"}
set :environment, 'development'

every 14.days, at: '5:00 am' do
  rake "sitemap:refresh"
end