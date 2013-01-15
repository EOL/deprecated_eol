# This is, quite simply, a class to round-robin our asset servers, so that their load is equally distributed (in theory).
class ContentServer

  @@next = 0 # This reults in the second entry being used first.  I'm okay with that; it's arbitrary where we begin.
  @@cache_url_re = /(\d{4})(\d{2})(\d{2})(\d{2})(\d+)/

  def self.next
    @@next += 1
    @@next = 0 if @@next > $CONTENT_SERVERS.length - 1
    return $CONTENT_SERVERS[@@next]
  end
  
  # this method will reliably return the same host for a given
  # asset, maintaining a decent amount of randomization. Designed
  # to avoid serving the same asset from different hosts in order
  # to improve caching
  def self.host_for(cache_url)
    # get ascii value of last character
    last_ascii_value = cache_url.to_s.getbyte(-1)
    # get the remainder of ASCII %(mod) LENGTH and use it as the array index
    $CONTENT_SERVERS[ (last_ascii_value % $CONTENT_SERVERS.length)]
  end
  

  def self.logo_path(url, size = nil)
    return self.blank if url.blank?
    logo_size = (size == "large") ? "_large.png" : "_small.png"
    if $CONTENT_SERVER_AGENT_LOGOS_PATH =~ /^http/
      "#{$CONTENT_SERVER_AGENT_LOGOS_PATH}#{url}#{logo_size}"
    else
      "#{self.next}#{$CONTENT_SERVER_AGENT_LOGOS_PATH}#{url}#{logo_size}"
    end
  end

  def self.cache_path(cache_url, options={})
    if (Rails.env.staging? || Rails.env.staging_dev?) && options[:is_crop] && $STAGING_CONTENT_SERVER
      options[:specified_content_host] = $STAGING_CONTENT_SERVER
    end
    if options[:specified_content_host]
      (options[:specified_content_host] + $CONTENT_SERVER_CONTENT_PATH + self.cache_url_to_path(cache_url))
    else
      (self.host_for(cache_url) + $CONTENT_SERVER_CONTENT_PATH + self.cache_url_to_path(cache_url))
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
    ($SINGLE_DOMAIN_CONTENT_SERVER + $CONTENT_SERVER_CONTENT_PATH + self.cache_url_to_path(url) + ext)
  end

  # only uploading logos
  def self.upload_content(path_from_root, port = nil)
    ip_with_port = $IP_ADDRESS_OF_SERVER.dup
    ip_with_port += ":" + port if port && !ip_with_port.match(/:[0-9]+$/)
    path_from_root = URI.encode(URI.encode(path_from_root))
    parameters = 'function=upload_content&file_path=http://' + ip_with_port + path_from_root
    response = EOLWebService.call(:parameters => parameters)
    if response.blank?
      ErrorLog.create(:url  => $WEB_SERVICE_BASE_URL, :exception_name  => "content partner logo upload service failed") if $ERROR_LOGGING
    else
      response = Hash.from_xml(response)
      if response["response"].class != Hash
        error = "Bad response: #{response["response"]}"
        ErrorLog.create(:url => $WEB_SERVICE_BASE_URL, :exception_name => error, :backtrace => parameters) if $ERROR_LOGGING
      elsif response["response"].key? "file_path"
        return response["response"]["file_path"] # this is the only return other than nil
      elsif response["response"].key? "error"
        error = response["response"]["error"]
        ErrorLog.create(:url => $WEB_SERVICE_BASE_URL, :exception_name => error, :backtrace => parameters) if $ERROR_LOGGING
      end
    end
    nil
  end

  # only uploading resources
  # returns [status, message]
  def self.upload_resource(file_url, resource_id)
    return nil if file_url.blank?
    return nil if resource_id.blank?
    parameters = "function=upload_resource&resource_id=#{resource_id}&file_path=#{file_url}"
    begin
      response = EOLWebService.call(:parameters => parameters)
    rescue
      ErrorLog.create(:url  => $WEB_SERVICE_BASE_URL, :exception_name  => "content provider dataset service has an error") if $ERROR_LOGGING
    end
    if response.blank?
      ErrorLog.create(:url  => $WEB_SERVICE_BASE_URL, :exception_name  => "content provider dataset service timed out") if $ERROR_LOGGING
    else
      response = Hash.from_xml(response)
      # set status to response - we've validated the resource
      if response["response"].key? "status"
        status = response["response"]["status"]
        error = response["response"]["error"] rescue nil
        resource_status = ResourceStatus.send(status.downcase.gsub(" ","_"))
        if resource_status != ResourceStatus.validated
          ErrorLog.create(:url=>$WEB_SERVICE_BASE_URL,:exception_name=>"content partner dataset service failed", :backtrace=>parameters) if $ERROR_LOGGING
        end
        return [resource_status, error]
      # response is an error
      elsif response["response"].key? "error"
        error = response["response"]["error"]
        ErrorLog.create(:url=>$WEB_SERVICE_BASE_URL,:exception_name=>"content partner dataset service failed", :backtrace=>parameters) if $ERROR_LOGGING
        return [ResourceStatus.validation_failed, nil]
      end
    end
    [ResourceStatus.validation_failed, nil]
  end

  def self.update_data_object_crop(data_object_id, x, y, w)
    return nil if data_object_id.blank?
    return nil if x.blank?
    return nil if y.blank?
    return nil if w.blank?
    begin
      env_name = Rails.env.to_s
      env_name = 'staging' if env_name == 'staging_dev'
      parameters = "function=crop_image&data_object_id=#{data_object_id}&x=#{x}&y=#{y}&w=#{w}&ENV_NAME=#{env_name}"
      response = EOLWebService.call(:parameters => parameters)
    rescue
      ErrorLog.create(:url => $WEB_SERVICE_BASE_URL, :exception_name  => "data object crop service has an error") if $ERROR_LOGGING
    end
    if response.blank?
      ErrorLog.create(:url => $WEB_SERVICE_BASE_URL, :exception_name  => "data object crop service failed") if $ERROR_LOGGING
    else
      response = Hash.from_xml(response)
      if response["response"].class != Hash
        error = "Bad response: #{response["response"]}"
        ErrorLog.create(:url => $WEB_SERVICE_BASE_URL, :exception_name => error, :backtrace => parameters) if $ERROR_LOGGING
      elsif response["response"].key? "file_path"
        return response["response"]["file_path"]
      elsif response["response"].key? "error"
        error = response["response"]["error"]
        ErrorLog.create(:url => $WEB_SERVICE_BASE_URL, :exception_name => error, :backtrace => parameters) if $ERROR_LOGGING
      end
    end
    nil
  end

end
