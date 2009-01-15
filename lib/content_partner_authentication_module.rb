module ContentPartnerAuthenticationModule
    
  # Protected authentication methods
  # ------------------------------------

  def agent_logged_in?
    current_agent.class==Agent
  end

  # Accesses the current agent from the session
  def current_agent
    @current_agent ||= (agent_login_from_session || agent_login_from_cookie) unless @current_agent == false
  end

  # Store the given agent id in the session
  def current_agent=(new_agent)
    session[:agent_id] = new_agent.is_a?(Agent) ? new_agent.id : nil
    @current_agent = new_agent || false
  end

  def agent_login_required
    agent_logged_in? || agent_access_denied
  end

  def agent_access_denied
    agent_store_location
    redirect_to url_for(:action => 'login')
  end

  def agent_store_location
    session[:agent_return_to] = request.request_uri
  end

  def agent_login_from_session
    self.current_agent = Agent.find_by_id(session[:agent_id]) if session[:agent_id]
  end

  def agent_login_from_cookie
    agent = cookies[:agent_auth_token] && Agent.find_by_remember_token(cookies[:agent_auth_token])
    if agent && agent.remember_token?
      cookies[:agent_auth_token] = { :value => agent.remember_token, :expires => agent.remember_token_expires_at }
      self.current_agent = agent
    end
  end

  def agent_redirect_back_or_default(default)
    redirect_to(session[:agent_return_to] || default)
    session[:agent_return_to] = nil
  end

  def is_user_admin?
    current_user.is_admin?
  end

  def agent_must_be_agreeable
    unless current_agent.ready_for_agreement?
      redirect_to :action => 'index', :controller => 'content_partner'
    end
  end

  def resource_must_belong_to_agent
    if params[:id] && !current_object.agents.include?(current_agent)
      flash[:notice]='The resource you selected is invalid.'
      redirect_to :controller=>'resources',:action=>'index'
    end
  end

  def upload_logo(agent)
    parameters='function=partner_image&file_path=http://' + $IP_ADDRESS_OF_SERVER + ":" + request.port.to_s + $LOGO_UPLOAD_PATH + agent.id.to_s + "."  + agent.logo_file_name.split(".")[-1]
    response=EOLWebService.call(:parameters=>parameters)
    if response.blank?
      ErrorLog.create(:url  => $WEB_SERVICE_BASE_URL, :exception_name  => "content partner logo upload service failed") if $ERROR_LOGGING
    else
      response = Hash.from_xml(response)
      if response["response"].key? "file_prefix"
        file_prefix = response["response"]["file_prefix"]
        agent.update_attribute(:logo_cache_url,file_prefix) # store new url to logo on content server      
      end
      if response["response"].key? "error"
        error = response["response"]["error"]
        ErrorLog.create(:url=>$WEB_SERVICE_BASE_URL,:exception_name=>error,:backtrace=>parameters) if $ERROR_LOGGING
      end
    end
  end  
  
end