module EOL
  module Login

    def log_in(user)
      if user.hidden?
        raise EOL::Exceptions::SecurityViolation.new(
          "Hidden User with ID=#{user.id} attempted to log in and was disallowed.",
          :hidden_user_login)
      end
      unless user.active?
        raise EOL::Exceptions::SecurityViolation.new(
          "Inactive User with ID=#{user.id} attempted to log in and was disallowed.",
          :inactive_user_login)
      end
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

  end
end

