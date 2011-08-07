module ImageManipulation

  def upload_logo(obj)
    if file_path = ContentServer.upload_content($LOGO_UPLOAD_PATH + obj.class.to_s.pluralize.downcase + "_" + obj.id.to_s + "."  + obj.logo_file_name.split(".")[-1])
      obj.update_attribute(:logo_cache_url, file_path) # store new url to logo on content server
    end
  end

end
