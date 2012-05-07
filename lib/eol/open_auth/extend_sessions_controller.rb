module EOL
  module OpenAuth
    # Overrides for sessions controller actions. Triggered when params are present that indicate
    # user has chosen to log in using an Open Authentication provider.
    module ExtendSessionsController

      # GET named route /login (sessions/new) handling open authentication callback and login
      def new
        oauth_provider = params.delete(:oauth_provider)
        @open_auth = EOL::OpenAuth.init(oauth_provider, login_url(:oauth_provider => oauth_provider), params.merge({
                          :request_token_token => session.delete("#{oauth_provider}_request_token_token"),
                          :request_token_secret => session.delete("#{oauth_provider}_request_token_secret")}))
        if @open_auth.have_attributes?
          if @open_auth.is_connected?
            @open_auth.open_authentication.connection_established
            log_in @open_auth.open_authentication.user
            return redirect_back_or_default user_newsfeed_url(@open_auth.open_authentication.user)
          else
            flash[:error] = I18n.t(:not_connected,
                                   :scope => [:users, :open_authentications, :errors, @open_auth.provider])

          end
        else
          flash[:error] = I18n.t(:missing_attributes,
                                 :scope => [:users, :open_authentications, :errors, @open_auth.provider])
        end
        # if we get here an error occurred, we redirect instead of render to remove oauth params
        redirect_to login_url
      end

      # POST /sessions handling open authentication authorization
      def create
        store_location(params[:return_to]) unless params[:return_to].blank?
        oauth_provider = params.delete(:oauth_provider)
        @open_auth = EOL::OpenAuth.init(oauth_provider, login_url(:oauth_provider => oauth_provider))
        @open_auth.prepare_for_authorization
        session.merge!(@open_auth.session_data) if defined?(@open_auth.request_token)
        return redirect_to @open_auth.authorize_uri
      end

    end
  end
end

