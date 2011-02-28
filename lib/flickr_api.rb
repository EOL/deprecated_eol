require 'digest/md5'
require 'net/http'

# In order to get an auth_token to use the editing APIs from Flickr you must authenticate.
# See http://www.flickr.com/services/api/auth.howto.web.html . Essentially you need to call
# self.login_url then go to that URL in a browser and log in as the user you want to authenticate.
# You will be returned to the Callback URL of the application you registered with Flickr. When you 
# are returned to the Callback it will include a frob. That frob needs to be converted to a token
# by calling self.auth_get_token, which will return the token. Authentication tokens currently
# do not expire.

class FlickrApi
  REST_API_PREFIX = 'http://api.flickr.com/services/rest/?'
  AUTH_API_PREFIX = 'http://api.flickr.com/services/auth/?'
  
  attr_reader :api_key
  attr_reader :secret
  attr_reader :auth_frob
  attr_reader :auth_token
  
  def initialize(params={})
    @api_key = params[:api_key]
    @secret = params[:secret]
    @auth_frob = params[:auth_frob]
    @auth_token = params[:auth_token]
  end
  
  def test_echo
    url = generate_rest_url("flickr.test.echo")
    JSON.parse(Net::HTTP.get(URI.parse(url)))
  end
  
  def auth_get_frob
    url = generate_rest_url("flickr.auth.getFrob")
    JSON.parse(Net::HTTP.get(URI.parse(url)))
  end
  
  def auth_check_token(t=@auth_token)
    url = generate_rest_url("flickr.auth.checkToken", {:auth_token => t})
    JSON.parse(Net::HTTP.get(URI.parse(url)))
  end
  
  def auth_get_token(f=@auth_frob)
    url = generate_rest_url("flickr.auth.getToken", {:frob => f})
    JSON.parse(Net::HTTP.get(URI.parse(url)))
  end
  
  def photos_get_info(photo_id, s=@secret, t=@auth_token)
    url = generate_rest_url("flickr.photos.getInfo", {:photo_id => photo_id, :secret => s, :auth_token => t})
    JSON.parse(Net::HTTP.get(URI.parse(url)))
  end
  
  def photos_add_comment(photo_id, text, s=@secret, t=@auth_token)
    return nil unless text
    params = {:photo_id => photo_id, :comment_text => text, :secret => s, :auth_token => t}
    url = generate_rest_url("flickr.photos.comments.addComment", params)
    rsp = JSON.parse(Net::HTTP.get(URI.parse(url)))
    sleep(5)
    # the first request failed. Seems to happen if the requests are too frequent, but we're not getting good error messages
    if(rsp['stat'] == 'fail')  # try once more
      sleep(5)  # wait an additional 5 seconds first
      rsp = JSON.parse(Net::HTTP.get(URI.parse(url)))
      sleep(5)
    end
    rsp
  end
  
  def photos_comments_get_list(photo_id, min_date=nil, max_date=nil, s=@secret, t=@auth_token)
    params = {:photo_id => photo_id, :secret => s, :auth_token => t}
    params[:min_comment_date] = min_date unless min_date.nil?
    params[:max_comment_date] = max_date unless max_date.nil?
    url = generate_rest_url("flickr.photos.comments.getList", params)
    JSON.parse(Net::HTTP.get(URI.parse(url)))
  end
  
  
  def login_url
    parameters = create_request_parameters
    parameters['perms'] = 'write'
    encoded_parameters = self.encode_parameters(parameters);
    AUTH_API_PREFIX + encoded_parameters.join('&') + '&api_sig=' + generate_signature(parameters)
  end
  
  def encode_parameters(parameters)
    encoded_paramameters = []
    parameters.each do |k, v|
      encoded_key = CGI.escape(k.to_s)
      encoded_value = CGI.escape(v.to_s)
      encoded_paramameters << CGI.escape(k.to_s) + '=' + CGI.escape(v.to_s)
    end
    encoded_paramameters
  end
  
  
  
  private
  
  def self.get_response(url)
    begin
      response = JSON.parse(Net::HTTP.get(URI.parse(url)))
      raise if !response || response.class != Hash
    rescue
      raise "FlickApi: Failed request: url"
      return
    end
    
    if response['stat'] != 'ok'
      raise "FlickApi: Error #{response['code']}: #{response['message']}"
      return
    end
  end
  
  def generate_rest_url(method, params={}, sign_request=true)
    parameters = create_request_parameters(method)
    params.each do |k,v|
      parameters[k] = v
    end
    
    encoded_paramameters = self.encode_parameters(parameters)
    url = REST_API_PREFIX + encoded_paramameters.join('&')
    if sign_request
      url += "&api_sig=" + generate_signature(parameters)
    end
    url
  end
  
  def create_request_parameters(method=nil, format='json', callback=nil)
    parameters = { 'api_key' => @api_key }
    parameters['method'] = method unless method.nil?
    parameters['format'] = format
    parameters['nojsoncallback'] = 1 unless callback
    parameters
  end
  
  def generate_signature(parameters={})
    signature = @secret.clone
    parameters = parameters.sort_by{|k,v| k.to_s }
    parameters.each do |k, v|
      signature += k.to_s + v.to_s
    end
    # ends up with signature=APIKEYkey1val1key2val2
    Digest::MD5.hexdigest(signature)
  end
end
