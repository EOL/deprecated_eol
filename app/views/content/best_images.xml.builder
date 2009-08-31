xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"
# xml.result do 
#   xml.head do
#     xml.title "Encyclopedia of Life #{@title}"
#     xml.description "Encyclopedia of Life images"
#     xml.link "http://www.eol.org/"
#   end
 
  xml.images do
    xml.title "Encyclopedia of Life #{@title}"
    
    @text_to_write.each do |item|
      xml.item(item.to_s) 
    end
  end
# end 
