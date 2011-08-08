class CommunitiesController < ApplicationController

  layout 'v2/communities'

  before_filter :allow_login_then_submit, :only => [:join]
  before_filter :load_community_and_dependent_vars, :except => [:index, :new, :create]
  before_filter :load_collection, :only => [:new, :create]
  before_filter :must_be_logged_in, :except => [:index, :show]
  before_filter :restrict_edit, :only => [:edit, :update]
  before_filter :restrict_delete, :only => [:delete]

  def index
    @communities = Community.paginate(:page => params[:page])
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @communities }
    end
  end

  def show
    respond_to do |format|
      format.html { redirect_to(community_newsfeed_path(params[:id] || params[:community_id])) }
      format.xml  { render :xml => @community }
    end
  end

  def new
    @page_title = I18n.t(:create_a_community)
    render :action => 'new', :layout => 'v2/new_community'
  end

  def edit
    @page_title = I18n.t(:edit_community)
  end

  def create
    # accepts_nested_attributes_for doesn't fully work on create... it'll work on update, though, so we deal w/ it:
    collection = Collection.new(params[:community].delete(:collection_attributes))
    @community = Community.new(params[:community])
    if @community.save
      @community.initialize_as_created_by(current_user)
      # NOTE - Because the collection is actually created by the on_create of the community, we need to update it:
      @community.collection.update_attribute(:name, collection.name)
      @community.collection.deep_copy(@collection) # NOTE this uses the OLD collection (see before_filters)
      invitees = params[:invite_list] ? params[:invite_list].values : params[:invitations].split(/[,\s]/).grep(/\w/)
      sent_to = send_invitations(invitees)
      notice = I18n.t(:created_community)
      notice += " #{I18n.t(:sent_invitations_to_users, :users => sent_to.to_sentence)}" unless sent_to.empty?
      upload_logo(@community) unless params[:community][:logo].blank?
      log_action(:create)
      redirect_to(@community, :notice => notice)
    else
      flash.now[:error] = I18n.t(:create_community_unsuccessful_error)
      render :action => "new", :layout => 'v2/new_community'
    end
  end

  def update
    name_change = params[:community][:name] != @community.name
    description_change = params[:community][:description] != @community.description
    #TODO = icon_change
    respond_to do |format|
      if @community.update_attributes(params[:community])
        upload_logo(@community) unless params[:community][:logo].blank?
        log_action(:change_name) if name_change
        log_action(:change_description) if description_change
        format.html { redirect_to(@community, :notice =>  I18n.t(:updated_community) ) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @community.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    # TODO - this shouldn't really be deleted, it shoud be hidden.  Also, it should log the activity.
    @community.destroy
    respond_to do |format|
      format.html { redirect_to(communities_url) }
      format.xml  { head :ok }
    end
  end

  def join
    if @community.has_member?(current_user)
      redirect_to(@community, :notice =>  I18n.t(:already_member_of_community) )
    else
      @community.add_member(current_user)
      respond_to do |format|
        format.html { redirect_to(@community, :notice =>  I18n.t(:you_joined_community) ) }
      end
    end
  end

  def leave
    @community.remove_member(current_user)
    respond_to do |format|
      format.html { redirect_to(@community, :notice =>  I18n.t(:you_left_community) ) }
    end
  end

private

  def load_community_and_dependent_vars
    begin
      @community = Community.find(params[:community_id] || params[:id])
    rescue => e
      @message = e.message
      render(:layout => 'v2/basic', :template => "content/missing", :status => 404)
      return false
    end
    @members = @community.members # Because we pull in partials from the members controller.
    @current_member = current_user.member_of(@community)
  end

  def load_collection
    @community = Community.new
    @collection = Collection.find(params[:collection_id])
    @community_collection = Collection.new(:name => I18n.t(:copy_of_name, :name => @collection.name))
  end

  def restrict_edit
    @current_member ||= current_user.member_of(@community)
    raise EOL::Exceptions::SecurityViolation unless @current_member && @current_member.manager?
  end

  def restrict_delete
    @current_member ||= current_user.member_of(@community)
    raise EOL::Exceptions::SecurityViolation unless @current_member && @current_member.manager?
  end

  def must_be_logged_in
    raise EOL::Exceptions::MustBeLoggedIn unless logged_in?
  end

  def log_action(act, opts = {})
    CommunityActivityLog.create(
      {:community => @community, :user => current_user, :activity => Activity.send(act)}.merge(opts)
    )
  end

  def send_invitations(usernames)
    sent_to = []
    not_sent_to = []
    usernames.each do |name|
      next if name.blank?
      begin
        user = User.find_by_username(name)
        comment = Comment.create(:parent => user, :user => current_user,
                                 :body => I18n.t(:community_invitation_comment, :community => link_to_name(@community)))
        sent_to << link_to_user(user)
      rescue
        not_sent_to << name
      end
    end
    unless not_sent_to.empty?
      flash[:error] = flash[:error].nil? ? '' : "#{flash[:error]} " # NOTE - add space if needed
      flash[:error] += I18n.t(:unable_to_invite_users_to_community_error, :users => not_sent_to.to_sentence)
    end
    return sent_to
  end

  def link_to_user(who)
    self.class.helpers.link_to(who.username, user_path(who))
  end

  def link_to_name(community)
    self.class.helpers.link_to(community.name, community_path(community))
  end

end
