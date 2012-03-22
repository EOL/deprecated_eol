class Users::OpenAuthenticationsController < UsersController

  layout 'v2/users'

  before_filter :authentication_only_allow_editing_of_self, :only => [:index, :create, :new]
  skip_before_filter :redirect_if_already_logged_in

  def index
    # @user instantiated by authentication before filter and matched to current user
  end

  def new
    # TODO: has user authorized? If so redirect with params to create. If not render index with error message.
    if params[:oauth_provider]
      if open_auth = EOL::OpenAuth.init(params[:oauth_provider], new_user_open_authentication_url(:oauth_provider => params[:oauth_provider]), params.merge({:request_token_token => session.delete("#{params[:oauth_provider]}_request_token_token"), :request_token_secret => session.delete("#{params[:oauth_provider]}_request_token_secret")}))
        if open_auth.user_attributes.nil? || open_auth.authentication_attributes.nil?
          flash.now[:error] = I18n.t(:oauth_error_accessing_basic_info)
        else
          if (authorized = OpenAuthentication.find_by_provider_and_guid(open_auth.authentication_attributes[:provider], open_auth.authentication_attributes[:guid], :include => :user)) && ! authorized.user.nil?
            # TODO: what do we do when we have authentication record but no user here?
            log_in(authorized.user)
            return redirect_to user_newsfeed_path(authorized.user)
          else
            params[:open_authentication] = open_auth.authentication_attributes
            return create
          end
        end
      else
        flash.now[:error] = I18n.t(:oauth_error_initializing_access)
      end
    end
    @user = User.new(oauth_user_attributes || nil)
  end

  def create
    if request.post? && open_authentication_provider = params[:open_authentication][:provider]
      # autorize url and redirect to confirm details new
      if open_auth = EOL::OpenAuth.init(open_authentication_provider, new_user_open_authentication_url(:oauth_provider => open_authentication_provider))
        session.merge!(open_auth.session_data) if defined?(open_auth.request_token)
        return redirect_to open_auth.authorize_uri
      else
        flash[:error] = I18n.t(:oauth_error_initializing_authorization, :oauth_provider => open_authentication_provider)
      end
    elsif request.get? && params[:open_authentication][:guid]
      # create new authentication record
      open_authentication = @user.open_authentications.build(params[:open_authentication])
      if open_authentication.save
        flash[:notice] = "Added #{params[:open_authentication][:provider]} authentication"
      else
        flash[:error] = "Error saving #{params[:open_authentication][:provider]} authentication"
      end
    end
    redirect_to :action => :index
  end

  private
  
  def open_authentication_providers
    @open_authentication_providers ||= @user.open_authentications.collect{ |oa| oa.provider } if @user.open_authentications
  end
  helper_method :open_authentication_providers

  # Save authentication information
  def save_profile_information(profile_information, options)
    authorized = Authentication.find_by_provider_and_guid(profile_information[:provider], profile_information[:guid])
    if logged_in? && authorized && current_user.id == authorized.user_id
      authorized.update_attributes(profile_information) # change notice to already logged in
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
      # begin
      #   # FIXME: Figure out whether we still need an agent to be created for a user in V2
      #   # If we do note that user does not have full_name on creation.
      #   new_user.update_attributes(:agent_id => Agent.create_agent_from_user(profile_information[:full_name]).id)
      # rescue ActiveRecord::StatementInvalid
      #   # Interestingly, we are getting users who already have agents attached to them.  I'm not sure why, but it's causing registration to fail (or seem to; the user is created), and this is bad.
      # end
      EOL::GlobalStatistics.increment('users')
      # FIXME: Fix blank email returned from twitter & yahoo
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
    if username.blank? || User.find_by_username(username) # username not provided or already exists in EOL
      username = "#{profile_information[:provider]}_#{profile_information[:guid]}"
    end
    username.slice(0..31)
  end

end