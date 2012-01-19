module EOL
  class ImageSitemap < EOL::Sitemap
    @@working_directory = File.join(RAILS_ROOT, 'public', 'sitemap', 'images')
    
    def initialize
      super
      @final_file_prefix = 'http://' + @@default_url_options[:host] + '/sitemap/images/sitemap_'
    end
    
    def build(options={})
      # :compress can be set to false, but if its nil we'll use the default value
      options[:compress] = (options[:compress].nil?) ? @@default_compression : options[:compress]
      # truncate existing sitemap file
      @all_link_tmp_file = File.open(@all_links_tmp_path, 'w')
      
      write_image_urls
      @all_link_tmp_file.close
      
      finalize(options)
    end
    
    def write_image_urls
      base_conditions = "published = 1 AND data_type_id = #{DataType.image.id} AND data_subtype_id IS NULL"
      # base_conditions = "published = 1"
      min_id, max_id = DataObject.connection.execute("SELECT MIN(id), MAX(id) FROM data_objects WHERE #{base_conditions}").fetch_row
      min_id = min_id.to_i
      max_id = max_id.to_i
      
      iteration_size = 50000
      start_time = Time.now
      start = min_id
      
      until start > max_id
        data_objects = DataObject.all(:select => { :data_objects => [ :id, :object_cache_url, :data_type_id ], :licenses => '*' },
          :conditions => base_conditions + " AND id BETWEEN #{start} AND #{start + iteration_size - 1}", :include => :license)
        data_objects.each do |data_object|
          image_metadata = { :loc => DataObject.image_cache_path(data_object.object_cache_url, '580_360', $SINGLE_DOMAIN_CONTENT_SERVER) }
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