class TaxaDownload
  @queue = :taxa_download

  def self.perform(data_point_uris_ids, user_id, collection_id)
    if data_point_uris_ids.any?
      data_point_uris = []
      data_point_uris_ids.each do |dpid|
        data_point_uris << DataPointUri.find(dpid)
      end
      collection_download_file = CollectionDownloadFile.create(user_id: user_id, collection_id: collection_id)
      collection_download_file.build_file(data_point_uris, User.find(user_id).language)
    end
  end
end
