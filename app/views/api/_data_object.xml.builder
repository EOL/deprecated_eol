unless data_object_hash.blank?
  xml.dataObject do
    xml.dc :identifier, data_object_hash['identifier']
    xml << render(:partial => 'data_object_metadata', :layout => false, :locals => { :data_object_hash => data_object_hash } )
  end
end
