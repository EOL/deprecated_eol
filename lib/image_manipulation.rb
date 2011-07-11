module ImageManipulation

  def upload_logo(obj)
    parameters = 'function=partner_image&file_path=http://' + $IP_ADDRESS_OF_SERVER + ":" + request.port.to_s + $LOGO_UPLOAD_PATH + obj.class.to_s.pluralize.downcase + "_" + obj.id.to_s + "."  + obj.logo_file_name.split(".")[-1]
    response = EOLWebService.call(:parameters => parameters)
    if response.blank?
      ErrorLog.create(:url  => $WEB_SERVICE_BASE_URL, :exception_name  => "content partner logo upload service failed") if $ERROR_LOGGING
    else
      response = Hash.from_xml(response)
      if response["response"].class != Hash
        error = "Bad response: #{response["response"]}"
        ErrorLog.create(:url => $WEB_SERVICE_BASE_URL, :exception_name => error, :backtrace => parameters) if $ERROR_LOGGING
      elsif response["response"].key? "file_prefix"
        file_prefix = response["response"]["file_prefix"]
        obj.update_attribute(:logo_cache_url, file_prefix) # store new url to logo on content server
      elsif response["response"].key? "error"
        error = response["response"]["error"]
        ErrorLog.create(:url => $WEB_SERVICE_BASE_URL, :exception_name => error, :backtrace => parameters) if $ERROR_LOGGING
      end
    end
  end

end
