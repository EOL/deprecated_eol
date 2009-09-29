xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"
xml.rss :version => "2.0", "xmlns:media".to_sym => "http://search.yahoo.com/mrss/", "xmlns:atom".to_sym => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title "Encyclopedia of Life images #{@title}"
    xml.description "Encyclopedia of Life images"
    xml.link "http://www.eol.org/"
    xml.atom :link, :href=>request.url,:rel=>'self', :type=>'application/rss+xml'  # How do you get a colon in the tag name?
    for item in @items
      xml.item do
        xml.title item[:title] || 'N/A'
        xml.link item[:link]
        xml.guid item[:guid], :isPermaLink => false
        xml.media :thumbnail, :url => item[:thumbnail]
        xml.media :content, :url => item[:image]
      end
    end
  end
end