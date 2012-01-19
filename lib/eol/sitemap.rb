module EOL
  class Sitemap
    require 'builder' # for creating XML
    include ActionController::UrlWriter # for using user_url(id) type methods
    @@default_url_options = { :host => 'eol.org' } # need to explicitly set the host for the above
    @@working_directory = File.join(RAILS_ROOT, 'public', 'sitemap')
    @@lines_per_sitemap_file = 50000.0
    @@default_compression = false
    
    def initialize
      Dir.glob(File.join(@@working_directory, 'tmp_*')).each { |f| File.delete(f) }
      @all_links_tmp_path = File.join(@@working_directory, 'tmp_all_links.txt')
      @index_path = File.join(@@working_directory, "index.xml")
      @batch_file_prefix = File.join(@@working_directory, "tmp_sitemap_")
      @final_file_prefix = 'http://' + @@default_url_options[:host] + '/sitemap/sitemap_'
    end
    
    def self.destroy_all_sitemap_files
      # we only care about files with extensions - so ignore all directories
      Dir.glob(File.join(@@working_directory, '*.*')).each { |f| File.delete(f) }
    end
    
    def build(options={})
      # :compress can be set to false, but if its nil we'll use the default value
      options[:compress] = (options[:compress].nil?) ? @@default_compression : options[:compress]
      # truncate existing sitemap file
      @all_link_tmp_file = File.open(@all_links_tmp_path, 'w')
      
      # some of our hard-coded routes
      write_url(discover_url)
      write_url(help_url)
      write_url(about_url)
      write_url(news_url)
      write_url(donate_url)
      write_url(contact_url)
      write_url(terms_of_use_url)
      write_url(citing_url)
      write_url(privacy_url)
      write_url(curators_url)
      
      # # proper objects
      write_cms_page_urls
      write_community_urls
      write_collection_urls
      write_content_partner_urls
      write_user_urls
      write_taxon_page_urls
      @all_link_tmp_file.close
      
      finalize(options)
    end
    
    def finalize(options={})
      number_of_sitemaps = split_into_smaller_files(options)
      # # delete the tmp file with all links
      File.delete(@all_links_tmp_path)
      # delete all published sitemaps
      Dir.glob(File.join(@@working_directory, 'sitemap_*')).each { |f| File.delete(f) }
      # rename tmp sitemaps to make them published
      Dir.glob(File.join(@@working_directory, 'tmp_sitemap_*')).each do |f|
        if m = f.match(/tmp_(sitemap.*$)/)
          File.rename(f, File.join(@@working_directory, m[1]))
        end
      end
      
      # overwrite the published sitemap index
      tmp_index_file = File.open(@index_path, 'w')
      tmp_index_file.puts sitemap_index_xml(number_of_sitemaps, options)
      tmp_index_file.close
    end
    
    # takes tmp_all_links and creates smaller files of no more than 50,000 links per the Sitemap spec
    # returns the count of sitemaps that were created
    def split_into_smaller_files(options={})
      line_count = 0
      sitemap_paths = []
      lines_in_batch = []
      index_of_batch = 0
      
      File.open(@all_links_tmp_path, 'r') do |working_file|
        while line = working_file.gets
          if line_count % @@lines_per_sitemap_file == 0
            create_sitemap_from_batch(lines_in_batch, index_of_batch, options)
            lines_in_batch = []
            index_of_batch += 1
          end
          lines_in_batch << line
          line_count += 1
        end
        
        # create another sitemap with the remainder
        create_sitemap_from_batch(lines_in_batch, index_of_batch, options)
      end
      index_of_batch
    end
    
    def create_sitemap_from_batch(lines, suffix, options={})
      return nil if lines.blank?
      if options[:xml]
        batch_file_path = write_batch_as_xml(lines, suffix, options)
      else
        batch_file_path = write_batch_as_text(lines, suffix, options)
      end
      gzip_file(batch_file_path) if options[:compress] && batch_file_path
    end
    
    # ## This is a different version of the method below. This version of the method uses XMLBuilder to generate
    # ## the XML for the file which consumes a bit of memory and is also significantly slower then the method
    # ## below. The version below writes the XML to the file directly as a string.
    # def write_batch_as_xml(lines, suffix, options={})
    #   lines.map!{ |l| JSON.parse(l) }
    #   batch_xml = Builder::XmlMarkup.new( :indent => 2 )
    #   batch_xml.instruct! :xml, :encoding => "UTF-8"
    #   xml = batch_xml.urlset(:xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9",
    #                          "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
    #                          "xmlns:image" => "http://www.google.com/schemas/sitemap-image/1.1",
    #                          "xsi:schemaLocation" => "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/sitemap.xsd http://www.google.com/schemas/sitemap-image/1.1 http://www.google.com/schemas/sitemap-image/1.1/sitemap-image.xsd") do |urlset|
    #     lines.each do |line_metadata|
    #       urlset.url do |url|
    #         # the properties need to appear in a certain order in order to be valid according
    #         # to the sitemap XSD
    #         ["loc", "lastmod", "changefreq", "priority"].each do |property|
    #           if value = line_metadata[property]
    #             url.tag! property, value
    #           end
    #         end
    #       end
    #     end
    #   end
    #   
    #   batch_file_path = @batch_file_prefix + "#{suffix}.xml"
    #   final_file = File.open(batch_file_path, 'w')
    #   final_file.puts xml
    #   final_file.close
    #   batch_file_path
    # end
    
    ## This is a different version of the method commented out above. The above method uses XMLBuilder and this
    ## one writes XML as strings. The SiteMap XML is very simple so we gain little from using XMLBuilder,
    ## so I've decided to use this method which is generally about 5 times faster than the above,
    ## saving more than an hour of processing time
    def write_batch_as_xml(lines, suffix, options={})
      lines.map!{ |l| JSON.parse(l) }
      batch_file_path = @batch_file_prefix + "#{suffix}.xml"
      batch_file = File.open(batch_file_path, 'w')
      batch_file.puts '<?xml version="1.0" encoding="UTF-8"?>'
      batch_file.puts '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"'
      batch_file.puts '  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
      batch_file.puts '  xmlns:image="http://www.google.com/schemas/sitemap-image/1.1"'
      batch_file.puts '  xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/sitemap.xsd http://www.google.com/schemas/sitemap-image/1.1 http://www.google.com/schemas/sitemap-image/1.1/sitemap-image.xsd">'
    
      lines.each do |line_metadata|
        url = "<url>"
        # the properties need to appear in a certain order in order to be valid according to the sitemap XSD
        ["loc", "lastmod", "changefreq", "priority"].each do |property|
          if value = line_metadata[property]
            url += "<#{property}>#{value}</#{property}>"
          end
        end
        if line_metadata["images"]
          line_metadata["images"].each do |image_metadata|
            url += "\n<image:image>"
            # the properties need to appear in a certain order in order to be valid according to the sitemap XSD
            ["loc", "caption", "geo_location", "title", "license"].each do |property|
              if value = image_metadata[property]
                url += "<image:#{property}>#{value}</image:#{property}>"
              end
            end
            url += "</image:image>"
          end
        end
        url += "</url>\n"
        batch_file.puts url
      end
      batch_file.puts '</urlset>'
      batch_file.close
      
      batch_file_path
    end
    
    
    def write_batch_as_text(lines, suffix, options={})
      lines.map!{ |l| JSON.parse(l) }
      batch_file_path = @batch_file_prefix + "#{suffix}.txt"
      batch_file = File.open(batch_file_path, 'w')
      
      lines.each do |line_metadata|
        batch_file.puts line_metadata['loc']
      end
      batch_file.close
      batch_file_path
    end
    
    def sitemap_index_xml(number_of_sitemaps, options={})
      xml = Builder::XmlMarkup.new( :indent => 2 )
      xml.instruct! :xml, :encoding => "UTF-8"
      xml.sitemapindex(:xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9",
                       "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                       "xsi:schemaLocation" => "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/siteindex.xsd") do |smi|
        (1..number_of_sitemaps).each do |suffix|
          smi.sitemap do |sm|
            url = @final_file_prefix + "#{suffix}."
            url += (options[:xml] ? 'xml' : 'txt')
            url += ".gz" if options[:compress]
            sm.loc url
          end
        end
      end
    end
    
    def write_taxon_page_urls
      base_conditions = "published = 1 AND supercedure_id = 0 AND vetted_id = #{Vetted.trusted.id}"
      min_id, max_id = TaxonConcept.connection.execute("SELECT MIN(id), MAX(id) FROM taxon_concepts WHERE #{base_conditions}").fetch_row
      min_id = min_id.to_i
      max_id = max_id.to_i
      
      iteration_size = 200000
      start_time = Time.now
      start = min_id
      
      until start > max_id
        concept_ids = TaxonConcept.connection.select_values("SELECT id FROM taxon_concepts WHERE #{base_conditions}
          AND id BETWEEN #{start} AND #{start + iteration_size - 1}")
        concept_ids.each do |tc_id|
          ## this is the proper way to get the metadata, but just using a string like below is more than 10 times faster
          # metadata = { :loc => taxon_overview_url(tc_id), :changefreq => 'weekly' }
          # @all_link_tmp_file.puts metadata.to_json
          
          url_prefix = '{"changefreq":"weekly","loc":"http://' + @@default_url_options[:host] + '/pages/' + tc_id + '/'
          { 'overview' => 1,
            'details' => 0.5,
            'media' => 0.5,
            'maps' => 0.1,
            'names' => 0.1,
            'community' => 0.1,
            'resources' => 0.1,
            'literature' => 0.1,
            'updates' => 0.1
          }.each do |path, priority|
            @all_link_tmp_file.puts url_prefix + path + '","priority":' + priority.to_s + '}'
          end
        end
        start += iteration_size
      end
    end
    
    def write_user_urls
      users = User.find(:all, :conditions => 'active = 1 AND (hidden = 0 OR hidden IS NULL)', :select => 'id, updated_at')
      users.each do |user|
        metadata = { :loc => user_url(user.id), :priority => 1 }
        metadata[:lastmod] = user.updated_at if user.updated_at
        @all_link_tmp_file.puts metadata.to_json
        metadata[:loc] = user_newsfeed_url(user.id)
        metadata[:priority] = 0.5
        @all_link_tmp_file.puts metadata.to_json
        metadata[:loc] = user_activity_url(user.id)
        metadata[:priority] = 0.5
        @all_link_tmp_file.puts metadata.to_json
      end
    end
    
    def write_collection_urls
      collections = Collection.find(:all, :conditions => 'published = 1', :select => 'id, updated_at')
      collections.each do |collection|
        metadata = { :loc => collection_url(collection.id), :priority => 1 }
        metadata[:lastmod] = collection.updated_at if collection.updated_at
        @all_link_tmp_file.puts metadata.to_json
        metadata[:loc] = collection_newsfeed_url(collection.id)
        metadata[:priority] = 0.5
        @all_link_tmp_file.puts metadata.to_json
      end
    end
    
    def write_community_urls
      communities = Community.find(:all, :conditions => 'published = 1', :select => 'id, updated_at')
      communities.each do |community|
        metadata = { :loc => community_url(community.id), :priority => 1 }
        metadata[:lastmod] = community.updated_at if community.updated_at
        @all_link_tmp_file.puts metadata.to_json
        metadata[:loc] = community_newsfeed_url(community.id)
        metadata[:priority] = 0.5
        @all_link_tmp_file.puts metadata.to_json
      end
    end
    
    def write_content_partner_urls
      content_partners = ContentPartner.find(:all, :conditions => 'public = 1', :select => 'id, updated_at')
      content_partners.each do |content_partner|
        metadata = { :loc => content_partner_url(content_partner.id), :changefreq => 'weekly', :priority => 1 }
        @all_link_tmp_file.puts metadata.to_json
      end
    end
    
    def write_cms_page_urls
      names_which_have_routes = [ 'help', 'about', 'news', 'explore_biodiversity',
                                  'contact', 'terms_of_use', 'citing', 'privacy', 'curators' ]
      content_pages = ContentPage.find(:all, :select => { :content_pages => [ :id, :page_name ] },
        :conditions => "active = 1 AND page_name NOT IN ('#{names_which_have_routes.join("', '")}')")
      content_pages.each do |content_page|
        page_url = cms_page_url(content_page.page_name)
        page_url.gsub!(/%20/, '_') # turn %20 into _
        page_url.gsub!(/&/, '&amp;') # turn & into &amp;
        metadata = { :loc => page_url, :changefreq => 'weekly', :priority => 1 }
        @all_link_tmp_file.puts metadata.to_json
      end
    end
    
    def write_url(url, priority = 1)
      metadata = { :loc => url, :priority => priority }
      @all_link_tmp_file.puts metadata.to_json
    end
    
    def gzip_file(path)
      new_path = path + '.gz'
      Zlib::GzipWriter.open(new_path) do |gz|
        gz.write IO.read(path)
      end
      File.delete(path)
      new_path
    end
    
  end
end