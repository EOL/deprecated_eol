module ImageManipulation

  def upload_logo(obj)
    if file_path = ContentServer.upload_content($LOGO_UPLOAD_PATH + obj.class.table_name + "_" + obj.id.to_s + "."  + obj.logo_file_name.split(".")[-1], request.port.to_s)
      obj.update_attributes(:logo_cache_url => file_path) # store new url to logo on content server
      # TODO: delete all other peer_sites' media_download_status for this entity
      # TODO: create new media_download_status for this thing
    end
  end

end
