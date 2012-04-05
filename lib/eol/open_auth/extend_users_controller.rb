module EOL
  module OpenAuth
    module ExtendUsersController

      # GET /users/register handling open authentication callbacks.
      def new
        oauth_provider = params.delete(:oauth_provider)
        open_auth = EOL::OpenAuth.init(oauth_provider, new_user_url(:oauth_provider => oauth_provider),
                                      params.merge({:request_token_token => session.delete("#{oauth_provider}_request_token_token"),
                                                    :request_token_secret => session.delete("#{oauth_provider}_request_token_secret")}))
        if open_auth.authorized?
          return if open_authentication_log_in(open_auth)
          session["oauth_token_#{open_auth.provider}_#{open_auth.guid}"] = open_auth.authentication_attributes[:token]
          session["oauth_secret_#{open_auth.provider}_#{open_auth.guid}"] = open_auth.authentication_attributes[:secret]
          @user = User.new(open_auth.user_attributes.merge({:open_authentications_attributes => [{
                                                              :guid => open_auth.guid, :provider => open_auth.provider }]}))
        else
          oauth_not_authorized
          @user = User.new
        end
      end

      # POST /users handling open authentication form submissions
      def create
        if oauth_provider = params.delete(:oauth_provider)
          open_auth = EOL::OpenAuth.init(oauth_provider, new_user_url(:oauth_provider => oauth_provider))
          open_auth.prepare_for_authorization
          session.merge!(open_auth.session_data) if defined?(open_auth.request_token)
          return redirect_to open_auth.authorize_uri
        end

        guid = params[:user][:open_authentications_attributes]["0"][:guid]
        provider = params[:user][:open_authentications_attributes]["0"][:provider]
        params[:user][:open_authentications_attributes]["0"][:token] = session["oauth_token_#{provider}_#{guid}"]
        params[:user][:open_authentications_attributes]["0"][:secret] = session["oauth_secret_#{provider}_#{guid}"]
        params[:user][:active] = true
        params[:user][:remote_ip] = request.remote_ip

        @user = User.new(params[:user])
        if @user.save # note no recaptcha for oauth signups
          EOL::GlobalStatistics.increment('users')
          session.delete("oauth_token_#{provider}_#{guid}")
          session.delete("oauth_secret_#{provider}_#{guid}")
          log_in(@user)
          redirect_to user_newsfeed_path(@user)
        else
          failed_to_create_user and return
        end
      end


      private

      def failed_to_create_user
        flash.now[:error] = I18n.t(:create_user_unsuccessful_error)
        render :action => :new, :layout => 'v2/sessions'
      end

      def oauth_not_authorized
        flash.now[:error] = I18n.t(:error_not_authorized, :scope => :open_authentications)
      end

    end
  end
end

