module EOL
  class Sitemap
    require 'builder' # for creating XML
    include ActionController::UrlWriter # for using user_url(id) type methods
    @@default_url_options = { :host => 'eol.org' } # need to explicitly set the host for the above
    
    def initialize
      # Dir.glob(File.join(RAILS_ROOT, 'public', 'sitemap', 'tmp_*')).each { |f| File.delete(f) }
      @all_links_tmp_path = File.join(RAILS_ROOT, 'public', 'sitemap', 'tmp_all_links.txt')
      @index_path = File.join(RAILS_ROOT, 'public', 'sitemap', "index.xml")
      @batch_file_prefix = File.join(RAILS_ROOT, 'public', 'sitemap', "tmp_sitemap_")
      @final_file_prefix = 'http://' + @@default_url_options[:host] + '/sitemap/sitemap_'
      @lines_per_sitemap_file = 50000.0
    end
    
    def self.destroy_all_sitemap_files
      Dir.glob(File.join(RAILS_ROOT, 'public', 'sitemap', '*')).each { |f| File.delete(f) }
    end
    
    def build(options={})
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
      
      number_of_sitemaps = split_into_smaller_files(options)
      # # delete the tmp file with all links
      File.delete(@all_links_tmp_path)
      # delete all published sitemaps
      Dir.glob(File.join(RAILS_ROOT, 'public', 'sitemap', 'sitemap_*')).each { |f| File.delete(f) }
      # rename tmp sitemaps to make them published
      Dir.glob(File.join(RAILS_ROOT, 'public', 'sitemap', 'tmp_sitemap_*')).each do |f|
        if m = f.match(/tmp_(sitemap.*$)/)
          File.rename(f, File.join(RAILS_ROOT, 'public', 'sitemap', m[1]))
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
          if line_count % @lines_per_sitemap_file == 0
            sitemap_paths << create_sitemap_from_batch(lines_in_batch, index_of_batch, options)
            lines_in_batch = []
            index_of_batch += 1
          end
          lines_in_batch << line
          line_count += 1
        end
        
        # create another sitemap with the remainder
        sitemap_paths << create_sitemap_from_batch(lines_in_batch, index_of_batch, options)
      end
      index_of_batch
    end
    
    def create_sitemap_from_batch(lines, suffix, options={})
      return nil if lines.blank?
      if options[:xml]
        write_batch_as_xml(lines, suffix, options={})
      else
        write_batch_as_text(lines, suffix, options={})
      end
    end
    
    def write_batch_as_xml(lines, suffix, options={})
      lines.map!{ |l| JSON.parse(l) }
      batch_xml = Builder::XmlMarkup.new( :indent => 2 )
      batch_xml.instruct! :xml, :encoding => "UTF-8"
      xml = batch_xml.urlset(:xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9") do |urlset|
        lines.each do |line_metadata|
          urlset.url do |url|
            line_metadata.each do |property, value|
              url.tag! property, value
            end
          end
        end
      end

      batch_file_path = @batch_file_prefix + "#{suffix}.xml"
      final_file = File.open(batch_file_path, 'w')
      final_file.puts xml
      final_file.close
      batch_file_path
    end
    
    def write_batch_as_text(lines, suffix, options={})
      batch_file_path = @batch_file_prefix + "#{suffix}.txt"
      batch_file = File.open(batch_file_path, 'w')
      
      lines.each do |line|
        metadata = JSON.parse(line)
        batch_file.puts metadata['loc']
      end
      batch_file.close
      batch_file_path
    end
    
    def sitemap_index_xml(number_of_sitemaps, options={})
      xml = Builder::XmlMarkup.new( :indent => 2 )
      xml.instruct! :xml, :encoding => "UTF-8"
      xml.sitemapindex(:xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9") do |smi|
        (1..number_of_sitemaps).each do |suffix|
          smi.sitemap do |sm|
            url = @final_file_prefix + "#{suffix}."
            url += (options[:xml] ? 'xml' : 'txt')
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
          @all_link_tmp_file.puts '{"changefreq":"weekly","loc":"http://' + @@default_url_options[:host] +
            '/pages/' + tc_id + '/overview"}'
        end
        start += iteration_size
      end
    end
    
    def write_user_urls
      users = User.find(:all, :conditions => 'active = 1 AND (hidden = 0 OR hidden IS NULL)', :select => 'id, updated_at')
      users.each do |user|
        metadata = { :loc => user_url(user.id) }
        metadata[:lastmod] = user.updated_at
        @all_link_tmp_file.puts metadata.to_json
      end
    end
    
    def write_collection_urls
      collections = Collection.find(:all, :conditions => 'published = 1', :select => 'id, updated_at')
      collections.each do |collection|
        metadata = { :loc => collection_url(collection.id) }
        metadata[:lastmod] = collection.updated_at
        @all_link_tmp_file.puts metadata.to_json
      end
    end
    
    def write_community_urls
      communities = Community.find(:all, :conditions => 'published = 1', :select => 'id, updated_at')
      communities.each do |community|
        metadata = { :loc => community_url(community.id) }
        metadata[:lastmod] = community.updated_at
        @all_link_tmp_file.puts metadata.to_json
      end
    end
    
    def write_content_partner_urls
      content_partners = ContentPartner.find(:all, :conditions => 'public = 1', :select => 'id, updated_at')
      content_partners.each do |content_partner|
        metadata = { :loc => content_partner_url(content_partner.id), :changefreq => 'weekly' }
        @all_link_tmp_file.puts metadata.to_json
      end
    end
    
    def write_cms_page_urls
      names_which_have_routes = [ 'help', 'about', 'news', 'explore_biodiversity',
                                  'contact', 'terms_of_use', 'citing', 'privacy', 'curators' ]
      content_pages = ContentPage.find(:all, :select => { :content_pages => [ :id, :page_name ] },
        :conditions => "active = 1 AND page_name NOT IN ('#{names_which_have_routes.join("', '")}')")
      content_pages.each do |content_page|
        metadata = { :loc => cms_page_url(content_page.page_name), :changefreq => 'weekly' }
        @all_link_tmp_file.puts metadata.to_json
      end
    end
    
    def write_url(url)
      metadata = { :loc => url }
      @all_link_tmp_file.puts metadata.to_json
    end
    
  end
end