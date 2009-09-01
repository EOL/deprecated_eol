# http://localhost:3000/pages/25/best_images.xml
xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"
 
xml.images do
  xml.title "Encyclopedia of Life #{@title}"
  
  @text_to_write.each do |item|
    xml.image do 
      xml.id item.id.to_s
      xml.description item.description
      xml.guid item.guid
      xml.rights_holder item.rights_holder
      xml.rights_statement item.rights_statement
      xml.data_supplier_agent item.data_supplier_agent
      xml.attributions do
        xml.author do
          item.agents.each do |agent|
            xml.author_name agent.full_name 
            xml.homepage agent.homepage 
          end        
        end
        xml.license do
          xml.type item.license.title
          xml.description item.license.description
        end
        xml.location item.location
        xml.source_url item.source_url        
      end
      xml.url item.thumb_or_object
      xml.medium_thumb_url item.thumb_or_object(:medium)
      xml.small_thumb_url item.thumb_or_object(:small)
    end
  end
end
