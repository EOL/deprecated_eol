# TODO: move this to lib/eol/logos ...This is strangely being made available
# everywhere. (Note you will have to fix "request" where it's used.)
module ImageManipulation
  def upload_logo(obj, options = {})
    ext = options[:name].split(".")[-1] if options[:name]
    # store new url to logo on content server
    if file_path = ContentServer.upload_content(
        Rails.configuration.logo_uploads.relative_path +
        ImageManipulation.local_file_name(obj, ext: ext), request.port.to_s
      )
      if file_path[:error]
        EOL.log("ERROR: Failed to update icon: #{file_path[:error]}",
          prefix: "!")
        raise file_path[:error]
      end
      if file_path.has_key?(:response) {
        obj.update_attributes(:logo_cache_url => file_path[:response])
      }
      end
    end
  end

  def self.local_file_name(obj, options = {})
    return '' unless obj.logo_file_name
    "#{obj.class.table_name}_#{obj.id.to_s}." +
      (options[:ext] || obj.logo_file_name.split(".")[-1])
  end
end
