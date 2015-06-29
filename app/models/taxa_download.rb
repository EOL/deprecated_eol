class TaxaDownload
  @queue = :taxa_download
  
  def self.perform(data_point_uris_ids, user_id, collection_id)
    if data_point_uris_ids.any?
      no_of_files = (data_point_uris_ids.size.to_f / DataSearchFile::LIMIT).ceil
      data_point_uris = []
      data_point_uris_ids.each do |dpid|
        data_point_uris << DataPointUri.find(dpid)
      end
      for count in 1..no_of_files
        collection_download_file = CollectionDownloadFile.create(user_id: user_id, collection_id: collection_id)
        collection_download_file.update_attributes(file_number: count)
        collection_download_file.build_file(data_point_uris, User.find(user_id).language)
      end
    end
  end
  
end