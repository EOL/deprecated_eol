module ImageManipulation

  def upload_logo(ip, obj)
    if file_path = ContentServer.upload_content(ip, $LOGO_UPLOAD_PATH + obj.class.table_name + "_" + obj.id.to_s + "."  + obj.logo_file_name.split(".")[-1], request.port.to_s)
      obj.update_attributes(:logo_cache_url => file_path) # store new url to logo on content server
    end
  end

end
