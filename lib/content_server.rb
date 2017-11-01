# This is, quite simply, a class to round-robin our asset servers, so that their load is equally distributed (in
# theory).
#
# TODO - do something when there are NO content servers, ie: in development.
class ContentServer
  @@cache_url_re = /(\d{4})(\d{2})(\d{2})(\d{2})(\d+)/

  def self.map(id)
    prefix = id.to_i % 100
    "https://media.eol.org/content/maps/#{prefix}/#{id}.json"
  end

  def self.jpg_sizes
    %w[580_360 260_190 130_130 98_68 88_88 orig]
  end

  def self.cache_path(cache_url, options={})
    if options[:specified_content_host]
      (options[:specified_content_host] + Rails.configuration.content_path + self.cache_url_to_path(cache_url))
    else
      Rails.configuration.asset_host + Rails.configuration.content_path + self.cache_url_to_path(cache_url)
    end
  end

  def self.cache_url_to_path(cache_url)
    new_path = cache_url.to_s.gsub(@@cache_url_re, "/\\1/\\2/\\3/\\4/\\5")
  end

  def self.blank
    "/assets/blank.gif"
  end

  def self.uploaded_content_url(url, ext)
    return self.blank if url.blank?
    Rails.configuration.asset_host + Rails.configuration.content_path + self.cache_url_to_path(url) + ext
  end

  # only uploading logos
  def self.upload_content(path_from_root, port = nil)
    ip_with_port = EOL::Server.ip_address.dup
    ip_with_port += ":" + port if port && !ip_with_port.match(/:[0-9]+$/)
    # NOTE - This used to call URI.encode *twice*. If you put that back,
    # _explain why_.
    parameters =
      "function=upload_content&file_path=" +
      "http://#{ip_with_port}#{URI.encode(path_from_root)}"
    call_file_upload_api_with_parameters(parameters,
      "content partner logo upload service")
  end

  # only uploading resources
  # returns [status, message]
  def self.upload_resource(file_url, resource_id)
    return nil if file_url.blank?
    return nil if resource_id.blank?
    parameters = "function=upload_resource&resource_id=#{resource_id}&file_path=#{file_url}"
    hash = call_api_with_parameters(parameters, "content partner dataset service")
    response = hash[:response]
    if response
      response = Hash.from_xml(response)
      # set status to response - we've validated the resource
      if response["response"].key?("status")
        status = response["response"]["status"]
        error = response["response"]["error"] rescue nil
        resource_status = ResourceStatus.send(status.downcase.gsub(" ","_"))
        if resource_status != ResourceStatus.validated
          EOL.log("ERROR: Content partner dataset service failed: "\
            "#{$WEB_SERVICE_BASE_URL}#{parameters} "\
            "error: #{error}", prefix: "*")
        end
        return [resource_status, error]
      # response is an error
      elsif response["response"].key? "error"
        EOL.log("ERROR: Content partner dataset service failed: "\
          "#{$WEB_SERVICE_BASE_URL}#{parameters} "\
          "error: #{response["response"]["error"]}", prefix: "*")
        return [ResourceStatus.validation_failed, response["response"]["error"]]
      end
    end
    [ResourceStatus.validation_failed, nil]
  end

  # TODO - these are hard-coded exceptions for OUR environment, just to appease
  # the conventions of PHP. The exceptions should be there, not here, if they
  # exist at all.
  def self.update_data_object_crop(data_object_id, x, y, w)
    return nil if data_object_id.blank?
    return nil if x.blank?
    return nil if y.blank?
    return nil if w.blank?
    parameters = "function=crop_image_pct&data_object_id=#{data_object_id}"\
      "&x=#{x}&y=#{y}&w=#{w}&ENV_NAME=#{Rails.env}"
    call_file_upload_api_with_parameters(parameters,
      "update data object crop service")
  end

  def self.upload_data_search_file(file_url, data_search_file_id)
    return nil if file_url.blank?
    return nil if data_search_file_id.blank?
    return file_url if Rails.configuration.local_services
    parameters = "function=upload_dataset&data_search_file_id=#{data_search_file_id}&file_path=#{file_url}"
    call_file_upload_api_with_parameters(parameters, "upload data search file service")
  end

  private

  def self.call_api_with_parameters(parameters, method_name)
    count = 0
    begin
      begin
        response = EOLWebService.call(parameters: parameters)
        return { response: response, exception: nil }
      rescue Exception => ex
        EOL.log("ERROR: #{method_name} #{$WEB_SERVICE_BASE_URL}#{parameters}",
          prefix: "!")
        EOL.log_error(ex)
      ensure
        count += 1
      end
    end while count < 3 # TODO: this should be configurable.
    return { response: nil, exception: "#{method_name} has an error" }
  end

  def self.call_file_upload_api_with_parameters(parameters, method_name)
    hash = call_api_with_parameters(parameters, method_name)
    response = hash[:response]
    exception = hash[:exception]
    error = nil
    if response.blank?
      if exception.nil?
        EOL.log("ERROR: #{method_name} timed out: "\
          "#{$WEB_SERVICE_BASE_URL}#{parameters}", prefix: "!")
        error = "#{method_name} timed out"
      else
        error = exception # couldn't connect
      end
    else
      begin
        response = Hash.from_xml(response)
      rescue REXML::ParseException => e
        msg = e.to_s.split("\n").first
        EOL.log("ERROR: [API CALL] (#{$WEB_SERVICE_BASE_URL}#{parameters}) "\
          "#{msg}")
      end
      if response["response"].class != Hash
        error = ""
        EOL.log("ERROR: Bad response: #{response["response"]} "\
          "#{$WEB_SERVICE_BASE_URL}#{parameters}", prefix: "!")
      elsif response["response"].key? "error"
        error = response["response"]["error"]
        EOL.log("ERROR: Bad response: #{response["response"]} "\
          "#{$WEB_SERVICE_BASE_URL}#{parameters}", prefix: "!")
      elsif response["response"].key? "file_path"
        path = response["response"]["file_path"]
        return path.blank? ? {response: nil, error: "File path is nil"} : {response: path, error: nil}
      end
    end
    return { response: nil, error: error }
  end

end
