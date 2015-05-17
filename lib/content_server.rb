# This is, quite simply, a class to round-robin our asset servers, so that their load is equally distributed (in
# theory).
#
# TODO - do something when there are NO content servers, ie: in development.

class ContentServer

  @@cache_url_re = /(\d{4})(\d{2})(\d{2})(\d{2})(\d+)/

  def self.jpg_sizes
    %w[580_360 260_190 130_130 98_68 88_88 orig]
  end

  def self.cache_path(cache_url, options={})
    if options[:specified_content_host]
      (options[:specified_content_host] + $CONTENT_SERVER_CONTENT_PATH + self.cache_url_to_path(cache_url))
    else
      $CONTENT_SERVER + $CONTENT_SERVER_CONTENT_PATH + self.cache_url_to_path(cache_url)
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
    $SINGLE_DOMAIN_CONTENT_SERVER + $CONTENT_SERVER_CONTENT_PATH + self.cache_url_to_path(url) + ext
  end

  # only uploading logos
  def self.upload_content(path_from_root, port = nil)
    ip_with_port = EOL::Server.ip_address.dup
    ip_with_port += ":" + port if port && !ip_with_port.match(/:[0-9]+$/)
    # NOTE - This used to call URI.encode *twice*. If you put that back, _explain why_.
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
    if response[:response] = call_api_with_parameters(parameters, "content partner dataset service")
      response = Hash.from_xml(response)
      # set status to response - we've validated the resource
      if response["response"].key? "status"
        status = response["response"]["status"]
        error = response["response"]["error"] rescue nil
        resource_status = ResourceStatus.send(status.downcase.gsub(" ","_"))
        if resource_status != ResourceStatus.validated
          ErrorLog.create(:url => $WEB_SERVICE_BASE_URL, :exception_name => "content partner dataset service failed", :backtrace => parameters) if $ERROR_LOGGING
        end
        return [resource_status, error]
      # response is an error
      elsif response["response"].key? "error"
        ErrorLog.create(:url => $WEB_SERVICE_BASE_URL, :exception_name => "content partner dataset service failed", :backtrace => parameters) if $ERROR_LOGGING
        return [ResourceStatus.validation_failed, response["response"]["error"]]
      end
    end
    [ResourceStatus.validation_failed, nil]
  end

  # TODO - these are hard-coded exceptions for OUR environment, just to appease the conventions of PHP. The exceptions should be there, not here, if they
  # exist at all.
  def self.update_data_object_crop(data_object_id, x, y, w)
    return nil if data_object_id.blank?
    return nil if x.blank?
    return nil if y.blank?
    return nil if w.blank?
    env_name = Rails.env.to_s
    env_name = 'staging' if Rails.env.staging_dev?
    env_name = 'bocce_demo' if Rails.env.bocce_demo_dev?
    parameters = "function=crop_image_pct&data_object_id=#{data_object_id}&x=#{x}&y=#{y}&w=#{w}&ENV_NAME=#{env_name}"
    call_file_upload_api_with_parameters(parameters, "update data object crop service")
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
        response = EOLWebService.call(:parameters => parameters)     
        return {response: response, exception: nil}
      rescue Exception => ex
        Rails.logger.error "#{$WEB_SERVICE_BASE_URL} #{method_name} #{ex.message}"
        ErrorLog.create(:url  => $WEB_SERVICE_BASE_URL, :exception_name  => "#{method_name} has an error") if $ERROR_LOGGING
      ensure
        count += 1
      end
    end while count < 5
    return {response: nil, exception: "#{method_name} has an error"}
  end

  def self.call_file_upload_api_with_parameters(parameters, method_name)
    hash = call_api_with_parameters(parameters, method_name)
    response = hash[:response]
    exception = hash[:exception]
    error = nil
    if response.blank? 
      if exception.nil?
        ErrorLog.create(:url  => $WEB_SERVICE_BASE_URL, :exception_name  => "#{method_name} timed out") if $ERROR_LOGGING
        error = "#{method_name} timed out"
      else
        error = exception # couldn't connect
      end
    else
      response = Hash.from_xml(response)
      if response["response"].class != Hash
        error = "Bad response: #{response["response"]}"
        ErrorLog.create(:url => $WEB_SERVICE_BASE_URL, :exception_name => error, :backtrace => parameters) if $ERROR_LOGGING
      elsif response["response"].key? "error"
        error = response["response"]["error"]
        ErrorLog.create(:url => $WEB_SERVICE_BASE_URL, :exception_name => error, :backtrace => parameters) if $ERROR_LOGGING
      elsif response["response"].key? "file_path"
        path = response["response"]["file_path"]
        return path.blank? ? {response: nil, error: "File path is nil"} : {response: path, error: nil}
      end
    end
    return {response: nil, error: error}
  end

end
