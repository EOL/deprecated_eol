module EOL
  module Login
    
    def log_in(user)
      session[:user_id] = user.id
      update_current_language(user.language)
      flash[:notice] = I18n.t(:sign_in_successful_notice)
      if params[:remember_me]
        if user.is_admin?
          flash[:notice] += " #{I18n.t(:sign_in_remember_me_disallowed_for_admins_notice)}"
        else
          user.remember_me
          cookies[:user_auth_token] = { :value => user.remember_token , :expires => user.remember_token_expires_at }
        end
      end
      session.delete(:recently_visited_collections) # Yes, it was requested that these be empty when you log in.
    end

    def login_existing_open_authentication_user(open_auth)
      if (open_authentication = OpenAuthentication.existing_authentication(open_auth.authentication_attributes[:provider], open_auth.authentication_attributes[:guid])) && (! open_authentication.user.nil?)
        log_in(open_authentication.user)
        open_authentication
      end
    end

    # Redirect to oauth provider to for authentication approval
    def initialize_open_authentication(authorize_callback, error_return_to = nil)
      if open_auth = EOL::OpenAuth.init(params[:oauth_provider], authorize_callback)
        session.merge!(open_auth.session_data) if defined?(open_auth.request_token)
        redirect_to open_auth.authorize_uri
      else
        flash[:error] = I18n.t(:oauth_error_initializing_authorization, :oauth_provider => oauth_provider)
        params.delete(:oauth_provider)
        redirect_to error_return_to unless error_return_to.nil?
      end
    end

    # Checks to make sure we have access to users basic information and authentication attributes
    def verify_open_authentication(authorize_callback)
      if (open_auth = EOL::OpenAuth.init(params[:oauth_provider], authorize_callback, params.merge({:request_token_token => session.delete("#{params[:oauth_provider]}_request_token_token"), :request_token_secret => session.delete("#{params[:oauth_provider]}_request_token_secret")})))
        if open_auth.user_attributes.nil? || open_auth.authentication_attributes.nil?
          flash.now[:error] = I18n.t(:oauth_error_accessing_basic_info)
        else
          return open_auth
        end
      else
        flash.now[:error] = I18n.t(:oauth_error_initializing_access)
      end
    end

  end
end
