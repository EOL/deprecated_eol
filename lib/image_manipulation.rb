module ImageManipulation

  def upload_logo(obj)
    if file_path = ContentServer.upload_content($LOGO_UPLOAD_PATH + ImageManipulation.local_file_name(obj), request.port.to_s)
      obj.update_attributes(:logo_cache_url => file_path) # store new url to logo on content server
    end
  end

  # TODO - this naming logic does not belong here. ...is it possible to get this from paperclip?  Seems that module knows about it. If not, we should move
  # it to a module that we include when we include paperclip... but it sure smells like it belongs with paperclip...
  def self.local_file_name(obj)
    obj.class.table_name + "_" + obj.id.to_s + "."  + obj.logo_file_name.split(".")[-1]
  end

end
