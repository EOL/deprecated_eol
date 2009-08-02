require 'zlib'

namespace :views do
  desc 'Renames all your rhtml views to erb'
  task :rename do
    Dir.glob('app/views/**/*.rhtml').each do |file|
      puts `svn mv #{file} #{file.gsub(/\.rhtml$/, '.html.erb')}`
    end
  end
end

namespace :cache do
   desc 'Clear memcache'
   task :clear => :environment do
     Rails.cache.clear
     ActionController::Base.cache_store.clear
   end
end

namespace :sitemap do


  desc 'Creates a series of Google Site Map files in the "RAILS_ROOT/tmp/sitemaps" folder, called with rake sitemap:create RAILS_ENV=production[ BASEURL="http://www.eol.org/pages/" BASEURL_SITEMAP="http://www.eol.org/sitemaps/" MAXPERFILE="50000" OUTPUTPREFIX="eol_sitemap" PRIORITY="1" CHANGEFREQ="monthly" LASTMOD="2009-03-01" EXTRAINFO="true"]'
  task :create => :environment do

    # sending the EXTRAINFO parameter will append two new nodes to each row, scientific name and page ID, useful for a full listing of valid EOL ids for a partner
    extra_info=ENV['EXTRAINFO'] || "false"
    
    base_url=ENV['BASEURL'] || 'http://www.eol.org/pages/'
    base_url_sitemap_files=ENV['BASEURL_SITEMAP'] || 'http://services.eol.org/sitemaps/'
        
    priority=ENV['PRIORITY'] || '1'
    changefreq=ENV['CHANGEFREQ'] || 'monthly'
    lastmod=ENV['LASTMOD'] || Date.today.strftime('%Y-%m-%d')

    max_per_file=ENV['MAXPERFILE'] || 50000
    max_per_file=max_per_file.to_i
    
    output_prefix=ENV['OUTPUTPREFIX'] || 'eol_sitemap'
    output_location="#{File.dirname(__FILE__)}/../../tmp/sitemaps/"

    # catalogue of life hierarchy ID
    CoLP_HE_id='106'
    # CoLP_HE_id='2' # testing for development
    
    sitemap_index_filename=output_location + output_prefix + '_index.xml'
    sitemap_index_file=File.open(sitemap_index_filename,'w')
    sitemap_index_file.write(SiteMap.sitemap_index_file_header)
     
    puts 'Getting unique published taxon concept IDs that are in CoLP...'
    taxa_ids=TaxonConcept.find_by_sql("SELECT tc.id,n.string namestring FROM taxon_concepts tc JOIN taxon_concept_names tcn ON (tc.id=tcn.taxon_concept_id) JOIN names n ON (tcn.name_id=n.id) JOIN hierarchy_entries he ON (tcn.source_hierarchy_entry_id=he.id) WHERE he.hierarchy_id=#{CoLP_HE_id} AND vern=0 AND preferred=1 AND tc.published=1 AND tc.supercedure_id=0;")
    
    # output results to CSV
    #SELECT tc.id,n.string namestring INTO OUTFILE '/tmp/EOL.csv' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' FROM taxon_concepts tc JOIN taxon_concept_names tcn ON (tc.id=tcn.taxon_concept_id) JOIN names n ON (tcn.name_id=n.id) JOIN hierarchy_entries he ON (tcn.source_hierarchy_entry_id=he.id) WHERE he.hierarchy_id=106 AND vern=0 AND preferred=1 AND tc.published=1 AND tc.supercedure_id=0;
    
    #taxa_ids=TaxonConcept.find_all_by_published_and_vetted_id(true,Vetted.trusted_ids)
    total_ids=taxa_ids.size

    puts "Found #{total_ids.to_s} taxon concept IDs that are in CoLP......"
    puts "Estimated number of files to be created is #{(total_ids.to_f/max_per_file.to_f).ceil}..."

    number_processed=0
    output_file_number=1
  
    # create first file
    output_filename=output_prefix + output_file_number.to_s+'.xml'
    output_path=output_location + output_filename
    puts "Creating #{output_filename}..."
    output_file=SiteMap.new_output_file(output_path)

    taxa_ids.each do |taxon|
        params={:loc=>base_url + taxon.id.to_s.chomp,:priority=>priority,:changefreq=>changefreq,:lastmod=>lastmod}
        params.merge!(:id=>taxon.id,:name=>taxon.namestring) if extra_info != 'false'
        sitemap_file=SiteMap.single_sitemap_file(params)
        output_file.write sitemap_file + "\n"
        number_processed+=1
        if (number_processed % max_per_file.to_i == 0) # time for a new file
          SiteMap.close_output_file(output_file)
          puts "GZIPing #{output_filename}..."
          SiteMap.gzip_file(output_path)
          File.delete(output_path)
          sitemap_index_file.write(SiteMap.sitemap_index_file_row(:loc=>base_url_sitemap_files + output_filename + '.gz',:lastmod=>lastmod) + "\n")
          output_file_number+=1
          output_filename=output_prefix + output_file_number.to_s+'.xml'
          output_path=output_location + output_filename
          puts "Creating #{output_filename}..."
          output_file=SiteMap.new_output_file(output_path)
        end
    end

    # close and gzip last file and then delete non GZIPed last file
    SiteMap.close_output_file(output_file)
    puts "GZIPing #{output_filename}..."  
    SiteMap.gzip_file(output_path)   
    File.delete(output_path)

    sitemap_index_file.write(SiteMap.sitemap_index_file_row(:loc=>base_url_sitemap_files + output_filename + '.gz',:lastmod=>lastmod) + "\n")    
    sitemap_index_file.write(SiteMap.sitemap_index_file_footer)
    sitemap_index_file.close
    puts "Complete - #{output_file_number.to_s} files created in 'RAILS_ROOT/tmp/sitemaps'."
        
  end

end


############################


class SiteMap
  
  # creates a single Google sitemap XML file for a single URL in format
  # <url>
  #  <loc>http://www.example.com/</loc>
  #  <lastmod>2005-01-01</lastmod>
  #  <changefreq>monthly</changefreq>
  #  <priority>0.8</priority>
  # </url>
  # pass in the value of each node (e.g. :loc) as a parameter (defaults to blank)
  def self.single_sitemap_file(params={})
    
    output_string='<url>'
    output_string+="<loc>#{params[:loc] || ''}</loc>"
    output_string+="<lastmod>#{params[:lastmod] || ''}</lastmod>"
    output_string+="<changefreq>#{params[:changefreq] || ''}</changefreq>"
    output_string+="<priority>#{params[:priority] || ''}</priority>"
    output_string+="<id>#{params[:id] || ''}</id>" if !params[:name].nil?
    output_string+="<name>#{params[:name] || ''}</name>" if !params[:id].nil?
    output_string+='</url>'
    
    return output_string
    
  end
  
  def self.sitemap_index_file_row(params={})
    
    output_string='<sitemap>'
    output_string+="<loc>#{params[:loc] || ''}</loc>"
    output_string+="<lastmod>#{params[:lastmod] || ''}</lastmod>"
    
    return output_string
    
  end
  
  def self.new_output_file(filename)
    
    output_file=File.open(filename,'w')
    output_file.write self.sitemap_file_header + "\n"
 
    return output_file
    
  end
  
  def self.close_output_file(file)

    file.write self.sitemap_file_footer + "\n"
    file.close
  
  end

  def self.gzip_file(filename)
    
    gzipped_filename=filename+'.gz'
    Zlib::GzipWriter.open(gzipped_filename) do |gz|
      gz.write(File.read(filename))
    end
    
  end
  
    
  def self.sitemap_file_header
    
    return '<?xml version="1.0" encoding="UTF-8"?>' + "\n" + '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    
  end

  def self.sitemap_file_footer
    
    return '</urlset>'
    
  end

  def self.sitemap_index_file_header
    
    return '<?xml version="1.0" encoding="UTF-8"?>' + "\n" + '<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' + "\n"
    
  end

  def self.sitemap_index_file_footer
    
    return '</sitemapindex>'
    
  end
  
end
