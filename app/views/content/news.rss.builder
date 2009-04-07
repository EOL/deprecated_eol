xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "EOL News"
    xml.description "Encyclopedia of Life News"
    xml.link request.url
    
    if !@news_items.blank?
      for news_item in @news_items
        if news_item.visible?
          xml.item do
            xml.title news_item.summary
            xml.link url_for(:only_path=>false,:controller=>'content',:action=>'news',:id=>news_item.id)
            xml.description news_item.body
            xml.pubDate news_item.display_date.to_s(:rfc822)
            xml.guid news_item.id
          end
        end
      end
    end
  end
end