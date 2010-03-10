unless object_hash.blank?
  xml.dataObject do
    xml.dc :identifier, object_hash["guid"]
    xml.dataType object_hash["data_type"]
    xml.subject object_hash["subject"] unless object_hash["subject"].blank?
  end
end
