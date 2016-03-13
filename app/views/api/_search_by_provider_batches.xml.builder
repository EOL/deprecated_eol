json_response.each do |response|
  key = response.keys[0]
  xml.page do
    xml.identifier key unless key.blank?
    response[key].each do |res|
      xml.eol_page_id res['eol_page_id'] unless res['eol_page_id'].blank?
      xml.eol_page_link res['eol_page_link'] unless res['eol_page_link'].blank?
    end
  end
end