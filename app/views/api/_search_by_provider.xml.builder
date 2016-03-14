json_response.each do |concept|
  xml.eol_page_id concept['eol_page_id'] unless concept['eol_page_id'].blank?
  xml.eol_page_link concept['eol_page_link'] unless concept['eol_page_link'].blank?
end