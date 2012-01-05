xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"

xml.urlset "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9" do
  line_metadata ||= []
  line_metadata.each do |metadata|
    xml.url do
      metadata.each do |property, value|
        xml.tag! property, value
      end
    end
  end
end