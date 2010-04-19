xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.response do                                                                                                               
  unless error.blank?
    xml.error do
      xml.message error
    end
  end
end
