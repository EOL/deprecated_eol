module EOL
  class ImageSitemap < EOL::Sitemap
    
    def initialize
      super
      @working_directory = Rails.root.join(Rails.public_path, 'sitemap', 'images')
      @final_file_prefix = 'http://' + @@default_url_options[:host] + '/sitemap/images/sitemap_'
    end
    
    def self.working_directory
      Rails.root.join(Rails.public_path, 'sitemap', 'images')
    end
    
    def build(options={})
      # :compress can be set to false, but if its nil we'll use the default value
      options[:compress] = (options[:compress].nil?) ? @@default_compression : options[:compress]
      # truncate existing sitemap file
      @all_link_tmp_file = File.open(@all_links_tmp_path, 'w')
      
      write_image_urls
      @all_link_tmp_file.close
      
      finalize(options.merge({ :use_xml_builder => true }))
    end
    
    def write_image_urls
      base_conditions = "published = 1"
      min_id, max_id = DataObject.connection.execute("SELECT MIN(id), MAX(id) FROM data_objects WHERE #{base_conditions}").first
      min_id = min_id.to_i
      max_id = max_id.to_i
      
      iteration_size = 50000
      start_time = Time.now
      start = min_id
      
      until start > max_id
        data_objects = DataObject.all(:select => 'id, object_cache_url, data_type_id, object_title, location, description, license_id',
          :conditions => base_conditions + " AND id BETWEEN #{start} AND #{start + iteration_size - 1} AND data_type_id=#{DataType.image.id}")
        DataObject.preload_associations(data_objects, :license)
        data_objects.each do |data_object|
          image_metadata = { :loc => DataObject.image_cache_path(data_object.object_cache_url, '580_360', :specified_content_host => Rails.configuration.asset_host) }
          image_metadata[:title] = data_object.object_title unless data_object.object_title.blank?
          image_metadata[:geo_location] = data_object.location unless data_object.location.blank?
          # license field asks for a URL so only include the Creative Commons URLs
          if data_object.license && data_object.license.source_url.match(/creativecommons\.org/)
            image_metadata[:license] = data_object.license.source_url
          end
          metadata = { :loc => data_object_url(data_object.id), :images => [ image_metadata ] }
          @all_link_tmp_file.puts metadata.to_json
        end
        start += iteration_size
      end
    end
  end
end
