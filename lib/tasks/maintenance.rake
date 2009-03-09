require 'rexml/document'
require 'zlib'

namespace :views do
  desc 'Renames all your rhtml views to erb'
  task :rename do
    Dir.glob('app/views/**/*.rhtml').each do |file|
      puts `svn mv #{file} #{file.gsub(/\.rhtml$/, '.html.erb')}`
    end
  end
end
    
namespace :sitemap do

  desc 'Creates a series of Google Site Map files in the "RAILS_ROOT/tmp/sitemaps" folder, called with rake sitemap:create RAILS_ENV=production[,BASEURL="http://www.eol.org/pages/",BASEURL_SITEMAP="http://www.eol.org/sitemaps/",MAXPERFILE="50000",OUTPUTPREFIX="eol_sitemap",PRIORITY="1",CHANGEFREQ="monthly",LASTMOD="2009-03-01"]'
  task :create => :environment do

    base_url=ENV['BASEURL'] || 'http://www.eol.org/pages/'
    base_url_sitemap_files=ENV['BASEURL_SITEMAP'] || 'http://services.eol.org/sitemaps/'
        
    priority=ENV['PRIORITY'] || '1'
    changefreq=ENV['CHANGEFREQ'] || 'monthly'
    lastmod=ENV['LASTMOD'] || Date.today.strftime('%Y-%m-%d')

    max_per_file=ENV['MAXPERFILE'] || 50000
    max_per_file=max_per_file.to_i
    
    output_prefix=ENV['OUTPUTPREFIX'] || 'eol_sitemap'
    output_location="#{File.dirname(__FILE__)}/../../tmp/sitemaps/"
    
    sitemap_index_filename=output_location + output_prefix + '_index.xml'
    sitemap_index_file=File.open(sitemap_index_filename,'w')
    sitemap_index_file.write(SiteMap.sitemap_index_file_header)
     
    puts 'Getting unique published and trusted taxon concept IDs...'
    taxa_ids=TaxonConcept.find_all_by_published_and_vetted_id(true,Vetted.trusted_ids)
    total_ids=taxa_ids.size

    puts "Found #{total_ids.to_s} unique published and trusted taxon concept IDs..."
    puts "Estimated number of files to be created is #{(total_ids.to_f/max_per_file.to_f).ceil}..."

    number_processed=0
    output_file_number=1
  
    # create first file
    output_filename=output_prefix + output_file_number.to_s+'.xml'
    output_path=output_location + output_filename
    puts "Creating #{output_filename}..."
    output_file=SiteMap.new_output_file(output_path)

    taxa_ids.each do |taxon|
        sitemap_file=SiteMap.single_sitemap_file(:loc=>base_url + taxon.id.to_s.chomp,:priority=>priority,:changefreq=>changefreq,:lastmod=>lastmod)
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
    
    doc=REXML::Document.new

    e1=REXML::Element.new 'url'
    e2=e1.add_element 'loc'
    e2.text=params[:loc] || ''
    e2=e1.add_element 'lastmod'
    e2.text=params[:lastmod] || ''
    e2=e1.add_element 'changefreq'
    e2.text=params[:changefreq] || ''
    e2=e1.add_element 'priority'
    e2.text=params[:priority] || '' 
    
    doc << e1
    
    return doc.to_s
    
  end
  
  def self.sitemap_index_file_row(params={})
    
    e1=REXML::Element.new 'sitemap'
    e2=e1.add_element 'loc'
    e2.text=params[:loc] || ''
    e2=e1.add_element 'lastmod'
    e2.text=params[:lastmod] || ''
    
    return e1.to_s
    
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
