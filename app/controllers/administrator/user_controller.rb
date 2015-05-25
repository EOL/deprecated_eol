class Administrator::UserController  < AdminController

  layout 'deprecated/left_menu'

  before_filter :set_layout_variables

  before_filter :restrict_to_admins

  require 'csv'

  def index

    @page_title = I18n.t("web_users")

    @user_search_string = params[:user_search_string] || ''
    search_string_parameter = '%' + @user_search_string + '%'
    @start_date = params[:start_date] || "2008-02-28"
    @end_date = params[:end_date] || Date.today.to_s(:db)
    @blank_dates = EOLConvert.to_boolean(params[:blank_dates])
    export = params[:export]

    begin
      @start_date_db = (Date.parse(@start_date)).to_s(:db)
      @start_date = @start_date_db # Reformat the string we'll show on the page, too, 'cause this is nicer.
      @end_date_db = (Date.parse(@end_date)+1).to_s(:db)
      @end_date = @end_date_db
    rescue
    end

    blank_date_condition = ' OR (created_at is null)' unless @blank_dates

    condition = "( (created_at>=? AND created_at<=?) #{blank_date_condition}) AND (id=? OR email like ? OR username like ? OR given_name like ? OR identity_url like ? OR family_name like ? OR username like ?)"

    if export
      @users = User.find(:all,
        include: :notification,
        conditions: [condition,
        @start_date_db,
        @end_date_db,
        @user_search_string,
        search_string_parameter,
         search_string_parameter,
         search_string_parameter,
         search_string_parameter,
         search_string_parameter,
         search_string_parameter],
        order: 'created_at desc')
      csv = CSV.generate do |line|
        line << ['Id', 'Username', 'Name', 'Email', 'Registered Date', 'Disable Email?', 'Receive Newsletter?']
        @users.each do |u|
          created_at = ''
          created_at = u.created_at.strftime("%m/%d/%y - %I:%M %p %Z") unless u.created_at.blank?
          line << [u.id, u.username, u.full_name, u.email, created_at, u.disable_email_notifications, u.notification.eol_newsletter]
        end
       end

       send_data csv,
         type: 'text/csv; charset=iso-8859-1; header=present',
         filename: 'EOL_users_report_' + Time.now.strftime("%m_%d_%Y-%I%M%p") + '.csv',
         encoding: 'utf8',
         disposition: "attachment"
    end

    @users = User.paginate(
      conditions: [condition,
      @start_date_db,
      @end_date_db,
      @user_search_string,
      search_string_parameter,
       search_string_parameter,
       search_string_parameter,
       search_string_parameter,
       search_string_parameter,
       search_string_parameter],
      order: 'created_at desc', page: params[:page])


    @user_count = User.count(
      conditions: [condition,
        @start_date_db,
        @end_date_db,
      @user_search_string,
      search_string_parameter,
      search_string_parameter,
      search_string_parameter,
      search_string_parameter,
      search_string_parameter,
      search_string_parameter])

    User.preload_associations(@users, :content_partners)
  end

  def edit
    store_location(referred_url) if request.get?
    @user = User.find(params[:id])
    @page_title = I18n.t("edit_username", username: @user.username)
  end

  def new
    @page_title = I18n.t("new_user")
    store_location(referred_url) if request.get?
    @user = User.new(language_id: current_language.id)
  end

  def create

    @user = User.new(params[:user])
    @message = params[:message]

    Notifier.user_message(@user.full_name, @user.email, @message).deliver unless @message.blank?

    @user.password = @user.entered_password

    if @user.save
      if EOLConvert.to_boolean(params[:user][:curator_approved])
        @user.grant_curator(:full, by: current_user)
      end
      flash[:notice] = I18n.t("the_new_user_was_created")
      redirect_back_or_default(url_for(action: 'index'))
    else
      render action: 'new'
    end

  end

  def update

    @user = User.find(params[:id])
    @message = params[:message]
    if @user.blank?
      flash[:error] = I18n.t(:error_updating_user)
      render action: 'edit'
      return
    end

    past_curator_level_id = @user.curator_level_id
    Notifier.deliver_user_message(@user.full_name, @user.email, @message).deliver unless @message.blank?

    user_params = params[:user]

    unless user_params[:entered_password].blank? && user_params[:entered_password_confirmation].blank?
      if user_params[:entered_password].length < 4 || user_params[:entered_password].length > 16
        @user.errors[:base] << I18n.t(:password_must_be_4to16_characters)
        render action: 'edit'
        return
      end
      @user.password = user_params[:entered_password]
    end

    if @user.update_attributes(user_params)
      if params[:curator_denied] || params[:user][:curator_level_id].blank?
        @user.revoke_curator
      else
        if params[:user][:curator_level_id] != past_curator_level_id
          @user.update_attributes(curator_verdict_by: current_user,
                                  curator_verdict_at: Time.now,
                                  curator_approved: 1)
          @user.join_curator_community_if_curator
        end
      end
      @user.add_to_index
      flash[:notice] = I18n.t("the_user_was_updated")
      redirect_back_or_default(url_for(action: 'index'))
    else
      render action: 'edit'
    end
  end

  def destroy
    (redirect_to referred_url, status: :moved_permanently ;return) unless request.delete?
    user = User.find(params[:id])
    user.destroy
    flash[:notice] = I18n.t("admin_user_delete_successful_notice")
    redirect_to referred_url, status: :moved_permanently
  end

  def hide
    user = User.find(params[:id])
    user.hidden = 1
    user.save
    user.hide_comments(current_user)
    user.hide_data_objects
    # clear home page cached comments
    clear_cached_homepage_activity_logs
    flash[:notice] = I18n.t("admin_user_hide_successful_notice")
    redirect_to referred_url, status: :moved_permanently
  end

  def unhide
    user = User.find(params[:id])
    user.hidden = 0
    user.save
    user.unhide_comments(current_user)
    user.unhide_data_objects
    # clear home page cached comments
    clear_cached_homepage_activity_logs
    flash[:notice] = I18n.t("admin_user_unhide_successful_notice")
    redirect_to referred_url, status: :moved_permanently
  end

  # NOTE - these are here for convenience; when an admin is looking at the users view, they want to quickly be able to
  # grant or remove curatorship.  The curator controller is more detailed.
  def grant_curator
    @user = User.find(params[:id])
    @user.grant_curator(:full, by: current_user)
    respond_to do |format|
      format.html {
        redirect_to '/administrator/curator', status: :moved_permanently
      }
      format.js {
        render partial: 'administrator/curator/user_row', locals: {column_class: params[:class] || 'odd', user: @user}
      }
    end
  end
  def revoke_curator
    @user = User.find(params[:id])
    @user.revoke_curator
    respond_to do |format|
      format.html {
        redirect_to '/administrator/curator', status: :moved_permanently
      }
      format.js {
        render partial: 'administrator/curator/user_row', locals: {column_class: params[:class] || 'even', user: @user}
      }
    end
  end

  def clear_curatorship
    user = User.find(params[:id])
    user.revoke_curator
    user.save!
  end

  def login_as_user
      user = User.find_by_id(params[:id])
      if !user.blank?
        reset_session
        session[:user_id] = user.id
        flash[:notice] = I18n.t("you_have_been_logged_in_as_username", username: user.username)
        redirect_to root_url, status: :moved_permanently
      end
      return
  end

  def list_newsletter_emails
    @emails = User.newsletter.
      select([:given_name, :family_name, :username, :email, :curator_level_id]).
      map do |user|
        %Q{"#{user.full_name}" <#{user.email}>}
    end.sort.uniq
  end

  def deactivate
    if current_user.id != params[:id]
      user = User.find(params[:id])
      user.deactivate
      flash[:notice] = I18n.t(:user_no_longer_active_message)
      redirect_back_or_default
    end
  end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
