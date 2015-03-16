namespace :ggi do
  desc 'Create a JSON file with GGI data for all taxa in FALO'
  task :create_data_file => :environment do
    all_data = [ ]
    ids = Resource.find_by_title('FALO Classification').hierarchy.
      hierarchy_entries.pluck(:taxon_concept_id).uniq
    puts "[#{Time.now}] STARTING."
    ids.each_with_index do |id,i|
      puts "Fetching API for #{id} (#{i+1} of #{ids.count})"
      if taxon_data = get_ggi_json_bocce(id)
        all_data << taxon_data
      end
    end
    puts "[#{Time.now}] DONE."
    file_contents = '[' + all_data.map{ |d| d.to_json }.join(",\n") + ']'
    File.open(File.dirname(__FILE__) + '/../../public/falo_data.json', "w") do |f|
      f.write(file_contents)
    end
  end

  desc 'Create a JSON file with FALO IDs mapped to EOL IDs'
  task :create_mapping_file => :environment do
    File.open(File.dirname(__FILE__) + '/../../public/falo_mappings.json', "w") do |f|
      f.write(Resource.find_by_title('FALO Classification').hierarchy.hierarchy_entries.map{ |he|
        { falo_id: he.identifier, eol_id: he.taxon_concept_id }
      }.to_json)
    end
  end
end

def get_ggi_json_bocce(id)
  # for URL helpers
  include Rails.application.routes.url_helpers
  Rails.application.routes.default_url_options[:host] =
    ActionMailer::Base.default_url_options[:host] || EOL::Server.domain
  # need to explicitly set the host for the URL helpers
  @@default_url_options = { :host => Rails.application.routes.default_url_options[:host] }
  # Ie: http://eol.org/api/ggi/1.0/2448
  ggi_api_url = url_for(controller: '/api', action: 'ggi', id: id, cache_ttl: (60 * 60 * 24), only_path: false)
  uri = URI.parse(ggi_api_url)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  request.basic_auth($WEBSITE_HTTP_USER, $WEBSITE_HTTP_PASSWORD) if $WEBSITE_HTTP_USER
  return (JSON.parse(http.request(request).body) rescue nil)
end
