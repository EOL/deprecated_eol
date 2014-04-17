namespace :ggi do
  desc 'Craete a single file with all GGI data in it'
  task :create_file => :environment do
    # this whole section for IDs will eventually read from the database
    # and not a text file. We just need to harvest the FALO resource first
    ids =  [ ]
    File.open(File.dirname(__FILE__) + '/../../tmp/falo_ids.txt', "r") do |f|
      f.each_line do |line|
        id = line.strip.to_i
        ids << id if id && id != 0
      end
    end
    all_data = [ ]
    ids[0...10].each do |id|
      all_data << get_ggi_json_bocce(id)
      puts id
    end
    file_contents = '[' + all_data.map{ |d| d.to_json }.join(",\n") + ']'
    File.open(File.dirname(__FILE__) + '/../../public/falo_data.json', "w") do |f|
      f.write(file_contents)
    end
  end
end

def get_ggi_json_bocce(id)
  include Rails.application.routes.url_helpers # for URL helpers
  Rails.application.routes.default_url_options[:host] =
    ActionMailer::Base.default_url_options[:host] || EOL::Server.domain
  # need to explicitly set the host for the URL helpers
  @@default_url_options = { :host => Rails.application.routes.default_url_options[:host] }
  ggi_api_url = url_for(controller: '/api', action: 'ggi', id: id, cache_ttl: 2419200, only_path: false)
  uri = URI.parse(ggi_api_url)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  request.basic_auth($WEBSITE_HTTP_USER, $WEBSITE_HTTP_PASSWORD) if $WEBSITE_HTTP_USER
  return JSON.parse(http.request(request).body)
end
