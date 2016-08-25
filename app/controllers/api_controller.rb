class ApiController < ApplicationController

  skip_before_filter :original_request_params, :global_warning, :set_locale, :check_user_agreed_with_terms,
    :keep_home_page_fresh
  before_filter :set_default_format_to_xml, except: [ :ping_host ]
  before_filter :get_api_method, except: [ :ping_host, :render_test_response ]
  after_filter :set_cache_headers

  # most APIs use the `default_render` methods
  def pages
  end

  def data_objects
  end

  def search
  end

  def hierarchy_entries
  end

  def hierarchy_entries_descendants
  end

  def synonyms
  end

  def hierarchies
  end

  def provider_hierarchies
  end

  def search_by_provider
  end

  def ping
  end

  def collections
  end

  def ggi
    request.format = 'json'
  end

  def traits
    request.format = 'json'
  end

  def ping_host
    request.format = 'json'
    respond_to do |format|
      format.json { render json: { 'response' => { 'host' => request.host, 'port' => request.port } } }
    end
  end

  def render_test_response
    code = params[:code] || "Sorry, there was a problem"
    code = JSON.pretty_generate(JSON.parse(code)) if code.is_json?
    respond_to do |format|
      format.js do
        render partial: "api/render_test_response", locals: { code: code }
      end
    end
  end

  private

  # this method loads the API method Class => EOL::Api::Search::V1_0
  # gets a response hash from its `call` method => @hash = EOL::Api::Search::V1_0.call
  # creates an API log
  # then returns the hash for JSON or renders the XML view => app/views/api/search_1_0.xml.builder
  def default_render
    # if this api_method is blank, and error should already have been rendered
    return if @api_method.blank?
    if Rails.env.development? || Rails.env.test_dev?
      @json_response = @api_method.call(params)
    else
      begin
        @json_response = @api_method.call(params)
      rescue ActiveRecord::RecordNotFound => e
        return render_error(e.message, 404)
      rescue EOL::Exceptions::ApiException => e
        return render_error(e.message)
      rescue => e
        EOL.log("API error (#{@api_method})")
        EOL.log_error(e)
        return render_error('Sorry, there was a problem')
      end
    end

    # return the JSON object generated above, OR
    # render the default (or custom) partial for this method: e.g. api/search_1_0.xml.builder
    respond_to do |format|
      if @api_method::TEMPLATE
        xml_template = @api_method::TEMPLATE
      else
        xml_template = "api/#{params[:action]}_#{@api_method::VERSION.tr('.', '_')}"
      end
      format.xml { render template: xml_template, layout: false }
      format.json { render json: @json_response, callback: params[:callback] }
    end
  end

  # this method returns the class associated with this API method and version
  # e.g. for /api/search/1.0/Ursus, this loads EOL::Api::Search::V1_0
  # Or it fails and renders an error message, and returns nil
  def get_api_method
    return if params[:action] == 'index' && params[:controller] == 'api/docs'
    begin
      # load the parent module (e.g. EOL::Api::Search) to get the default version
      method_class = "EOL::Api::#{params[:action].camelize}".constantize
    rescue => e
      render_error("Invalid method: #{params[:action]}")
      return nil
    end

    begin
      # load the proper version of the API method (e.g. EOL::Api::Search::V1_0)
      params[:version] ||= method_class::DEFAULT_VERSION
      @api_method = "#{method_class}::V#{params[:version].tr('.', '_')}".constantize
    rescue => e
      render_error("Invalid version: #{params[:version]}")
      return nil
    end
    return @api_method
  end

  def render_error(error_message, status_code = 500)
    # default response for all API errors, with XML or JSON repsonses
    respond_to do |format|
      format.xml { render(partial: 'error', locals: { error: error_message }, status: status_code) }
      format.json { render(json: [ error: error_message ], callback: params[:callback], status: status_code ) }
      # API docs might have an error too, but in that case raise to get the default HTML error handling
      format.html { raise }
    end
  end

  def set_default_format_to_xml
    # all APIs return XML by default when no extension is given
    request.format = "xml" unless params[:format]
  end

  def set_cache_headers
    return if response.status != 200
    if params[:cache_ttl] && (params[:cache_ttl].class == Fixnum || params[:cache_ttl].is_numeric?)
      # between 0 and 1 year
      cache_seconds = params[:cache_ttl].to_i
      if cache_seconds >= 0 && cache_seconds < 31536000
        expires_in cache_seconds.seconds, public: true
      end
    else
      response.cache_control.replace({})
    end
  end

end
