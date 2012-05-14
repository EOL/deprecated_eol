module EOL
  module OpenAuth
    # Overrides for sessions controller actions. Triggered when params are present that indicate
    # user has chosen to log in using an Open Authentication provider.
    module ExtendSessionsController

      # GET named route /login (sessions/new) handling open authentication callback and login
      def new
        store_location(params[:return_to]) unless params[:return_to].blank?
        oauth_provider = params.delete(:oauth_provider)
        # Clean up session from previous incomplete authorizations, e.g. when users use browser back button
        session.delete_if{|k,v| k.to_s.match /^(?!#{oauth_provider})[a-z]+(?:_request_token_(?:token|secret)|_oauth_state)$/i}
        @open_auth = EOL::OpenAuth.init(oauth_provider, login_url(:oauth_provider => oauth_provider), params.merge({
                          :stored_state => session.delete("#{oauth_provider}_state"),
                          :request_token_token => session.delete("#{oauth_provider}_request_token_token"),
                          :request_token_secret => session.delete("#{oauth_provider}_request_token_secret")}))
        if @open_auth.access_denied?
          # Note: Access denied doesn't apply to Yahoo! they don't have a cancel button.
          raise EOL::Exceptions::OpenAuthUnauthorized,
            "Anonymous user denied access to login with #{@open_auth.provider}."
        elsif @open_auth.authorized?
          if @open_auth.have_attributes?
            if @open_auth.is_connected?
              create and return
            else
              # TODO: Maybe... add the connection automatically after user logs in with other credentials
              flash[:error] = I18n.t(:login_failed_not_connected,
                                     :login_url => login_url,
                                     :register_url => new_user_url(:oauth_provider => @open_auth.provider),
                                     :scope => [:users, :open_authentications, :errors, @open_auth.provider])
            end
          else
            flash[:error] = I18n.t(:missing_attributes,
                                   :scope => [:users, :open_authentications, :errors, @open_auth.provider])
          end
        else
          session.merge!(@open_auth.session_data)
          redirect_to @open_auth.authorize_uri and return
        end
        redirect_back_or_default login_url
      end

      # GET called directly from sessions/new
      # Open authentication does a lot of redirects and we can't POST to redirects so we go through :new
      def create
        if request.get? && params[:action] == 'new' && @open_auth
          @open_auth.open_authentication.connection_established
          log_in @open_auth.open_authentication.user
          redirect_back_or_default user_newsfeed_url(@open_auth.open_authentication.user)
        end
      end

    end
  end
end

