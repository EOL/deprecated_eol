class Crawler::SiteMapIndexer
  @filename = Rails.root.join("public", "traitbank-sitemap.xml").to_s
  @xmlns = "http://www.sitemaps.org/schemas/sitemap/0.9"
  class << self

    # <?xml version="1.0" encoding="UTF-8"?>
    # <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #   <sitemap>
    #     <loc>http://eol.org/traitbank-2016-05-12.json</loc>
    #     <lastmod>2016-05-18T18:27:05+0000</lastmod>
    #   </sitemap>
    # </sitemapindex>
    def create
      File.unlink(@filename) if File.exist?(@filename)
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.sitemapindex(xmlns: @xmlns) { }
      end
      File.open(@filename, "w") { |f| f.puts builder.to_xml }
    end

    # NOTE: Only works if the file is in /public.
    def add_sitemap(file)
      EOL.log("TODO: remove me, but: #add_sitemap (#{file})")
      filename = File.basename(file)
      mtime = File.mtime(file)
      doc = File.open(@filename) do |f|
        Nokogiri::XML(f) do |cfg|
          cfg.strict
          cfg.noblanks
        end
      end
      doc.css("//sitemap/loc").each do |loc|
        # puts("Content: /#{loc.content}/")
        # puts("We should remove this") if loc.content =~ /\/#{filename}$/
        loc.parent.remove if loc.content =~ /\/#{filename}$/
      end
      Nokogiri::XML::Builder.with(doc.at('sitemapindex')) do |xml|
        xml.sitemap do
          xml.loc "http://#{Rails.configuration.site_domain}/#{filename}"
          xml.lastmod mtime.strftime("%FT%T%z")
        end
      end
      File.open(@filename, "w") { |f| f.puts doc.to_xml }
    end
  end
end
