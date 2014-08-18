module ImageManipulation
  # TODO: move this to lib/eol/logos
  def upload_logo(obj)
    if file_path = ContentServer.upload_content(Rails.configuration.logo_uploads.paperclip_url + ImageManipulation.local_file_name(obj), request.port.to_s)
      obj.update_attributes(:logo_cache_url => file_path) # store new url to logo on content server
    end
  end

  def self.local_file_name(obj)
    obj.class.table_name + "_" + obj.id.to_s + "."  + obj.logo_file_name.split(".")[-1]
  end

end
