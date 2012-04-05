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

    def open_authentication_log_in(open_auth)
      if (open_authentication = OpenAuthentication.existing_authentication(open_auth.provider, open_auth.guid)) &&
         (! open_authentication.user.nil?)
        log_in(open_authentication.user)
        redirect_to user_newsfeed_path(open_authentication.user)
      end
    end

  end
end

