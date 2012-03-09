class Users::AuthenticationsController < UsersController

  OAUTH_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/oauth.yml")[RAILS_ENV]

  def authenticate
    provider_config = OAUTH_CONFIG["#{params[:provider]}"]
    redirect_url = "#{OAUTH_CONFIG['redirect_url']}?provider=#{params[:provider]}"
    case provider_config['type']
    when 'OAuth'
      client = EOL::Oauth.consumer(provider_config)
      request_token = client.get_request_token(:oauth_callback => redirect_url)
      # Save received token and secret in session
      session["#{params[:provider]}_request_token_token"] = request_token.token
      session["#{params[:provider]}_request_token_secret"] = request_token.secret
      redirect_to request_token.authorize_url
    when 'OAuth2'
      client = EOL::Oauth.consumer2(provider_config)
      redirect_to client.auth_code.authorize_url((provider_config['authorize_url_params'] || {}).merge(:redirect_uri => redirect_url))
    else
      # Failed to get client information for provider: #{params[:provider]}
      flash[:notice] = I18n.t(:oauth_sign_in_unsuccessful_error)
      redirect_back_or_default
    end
  end

  def callback
    provider_config = OAUTH_CONFIG["#{params[:provider]}"]
    case provider_config['type']
    when 'OAuth'
      client = EOL::Oauth.consumer(provider_config)
      request_token = OAuth::RequestToken.new(client, session["#{params[:provider]}_request_token_token"], session["#{params[:provider]}_request_token_secret"])
      access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
    when 'OAuth2'
      client = EOL::Oauth.consumer2(provider_config)
      redirect_url = "#{OAUTH_CONFIG['redirect_url']}?provider=#{params[:provider]}"
      access_token = client.auth_code.get_token(params[:code], (provider_config['access_token_params'] || {}).merge(:redirect_uri => redirect_url))
    else
      # Failed to get consumer information for OAuth provider #{params[:provider]}
      redirect_back_or_default
    end

    if profile_information = EOL::Oauth.profile(params[:provider], access_token)
      profile_information[:provider] = params[:provider]
      save_profile_information(profile_information, :remote_ip => request.remote_ip)
    else
      flash[:notice] = I18n.t(:oauth_sign_in_unsuccessful_error)
      redirect_back_or_default
    end
  end

  private

  # Save authentication information
  def save_profile_information(profile_information, options)
    authorized = Authentication.find_by_provider_and_guid(profile_information[:provider], profile_information[:guid])
    if logged_in? && authorized && current_user.id == authorized.user_id
      authorized.update_attributes(profile_information)
      flash[:notice] = I18n.t(:sign_in_successful_notice)
    elsif logged_in? && !authorized && Authentication.create({ :user_id => current_user.id }.merge(profile_information))
      flash[:notice] = I18n.t(:oauth_authentication_added_and_sign_in_successful, :oauth_provider => profile_information[:provider])
    elsif !logged_in? && authorized
      authorized.update_attributes(profile_information)
      oauthenticate(authorized, :message => I18n.t(:sign_in_successful_notice))
    elsif !logged_in? && !authorized
      if new_user = create_new_eol_user(profile_information, options)
        new_authentication = Authentication.create({ :user_id => new_user.id }.merge(profile_information))
        oauthenticate(new_authentication, :message => I18n.t(:oauth_eol_account_created_and_authentication_added, :oauth_provider => profile_information[:provider]))
      else
        flash[:notice] = I18n.t(:oauth_sign_in_unsuccessful_error)
      end
    else
      flash[:notice] = I18n.t(:oauth_sign_in_unsuccessful_error)
    end
    redirect_back_or_default
  end

  def oauthenticate(authentication, options)
    if authenticated = Authentication.authenticate(authentication)
      reset_session
      set_current_user(authentication.user)
      flash[:notice] = options[:message]
    else
      flash[:notice] = I18n.t(:oauth_sign_in_unsuccessful_error)
    end
  end

  # Create new EOL user
  def create_new_eol_user(profile_information, options)
    # Get username no more than 32 characters
    username = get_user_name(profile_information)
    # Get random password no more than 16 characters
    password = (0...16).map{65.+(rand(25)).chr}.join
    
    # Create new user
    new_user = User.create_new(
                 :username => username,
                 :given_name => profile_information[:given_name],
                 :family_name => profile_information[:family_name],
                 :email => profile_information[:email].nil? ? "oauth_user" : profile_information[:email],
                 :entered_password => password, 
                 :entered_password_confirmation => password,
                 :remote_ip => options[:remote_ip]
                 )
    if new_user.save
    #   begin
    #     # FIXME: Figure out whether we still need an agent to be created for a user in V2
    #     # If we do note that user does not have full_name on creation.
    #     @user.update_attributes(:agent_id => Agent.create_agent_from_user(profile_information[:full_name]).id)
    #   rescue ActiveRecord::StatementInvalid
    #     # Interestingly, we are getting users who already have agents attached to them.  I'm not sure why, but it's causing registration to fail (or seem to; the user is created), and this is bad.
    #   end
      EOL::GlobalStatistics.increment('users')
      if new_user.email == "oauth_user"
        new_user.update_attribute(:email, "")
      end
      new_user
    else
      nil
    end
  end

  # return username no more than 32 characters
  def get_user_name(profile_information)
    username = profile_information[:user_name]
    username_already_exists = User.find_by_username(username)
    if username_already_exists
      username = "#{profile_information[:user_name]}_#{profile_information[:guid]}_#{profile_information[:provider]}".slice(0..31)
    else
      username = profile_information[:user_name].slice(0..31)
    end
  end

end