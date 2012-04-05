module EOL
  module OpenAuth
    module ExtendSessionsController

      # GET named route /login (sessions/new) handling open authentication callback and login
      def new
        # TODO: handle return to URLs
        oauth_provider = params.delete(:oauth_provider)
        open_auth = EOL::OpenAuth.init(oauth_provider, login_url(:oauth_provider => oauth_provider),
                                       params.merge({:request_token_token => session.delete("#{oauth_provider}_request_token_token"),
                                                     :request_token_secret => session.delete("#{oauth_provider}_request_token_secret")}))
        if open_auth.authorized?
          return if open_authentication_log_in(open_auth)
          flash.now[:error] = I18n.t(:authorized_user_not_found, :scope => [:users, :open_authentications, :errors, oauth_provider.to_sym])
        end
        @rel_canonical_href = login_url
      end

      # POST /sessions handling open authentication authorization
      def create
        oauth_provider = params.delete(:oauth_provider)
        open_auth = EOL::OpenAuth.init(oauth_provider, login_url(:oauth_provider => oauth_provider))
        open_auth.prepare_for_authorization
        session.merge!(open_auth.session_data) if defined?(open_auth.request_token)
        return redirect_to open_auth.authorize_uri
      end

    end
  end
end

