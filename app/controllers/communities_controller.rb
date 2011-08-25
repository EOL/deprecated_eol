class CommunitiesController < ApplicationController

  layout 'v2/communities'

  before_filter :allow_login_then_submit, :only => [:join]
  before_filter :load_community_and_dependent_vars, :except => [:index, :new, :create]
  before_filter :load_collection, :only => [:new, :create]
  before_filter :must_be_logged_in, :except => [:index, :show]
  before_filter :restrict_edit, :only => [:edit, :update, :destroy]

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
    if @collection.special?
      flash[:error] = I18n.t(:cannot_create_community_from_watch_collection_error)
      return redirect_to @collection
    end
    @community = Community.new(params[:community])
    if @community.save
      @collection.update_attribute(:user_id, nil)
      @collection.update_attribute(:community_id, @community.id)
      @community.initialize_as_created_by(current_user)
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
        invitees = params[:invite_list] ? params[:invite_list].values : params[:invitations].split(/[,\s]/).grep(/\w/)
        sent_to = send_invitations(invitees)
        notice = sent_to.empty? ? nil : I18n.t(:sent_invitations_to_users, :users => sent_to.to_sentence)
        upload_logo(@community) unless params[:community][:logo].blank?
        log_action(:change_name) if name_change
        log_action(:change_description) if description_change
        format.html { redirect_to(@community, :notice => [I18n.t(:updated_community), notice].compact.to_sentence) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @community.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Note this is not "destroy".  That's because it's different: the community instance is not destroyed, AND this is a :get, not a :post.
  def delete
    if @community.update_attribute(:published, false)
      begin
        @community.remove_member(current_user)
      rescue EOL::Exceptions::ObjectNotFound => e
        flash[:error] = I18n.t(:could_not_find_user)
      end
      log_action(:delete)
      # TODO - it might make sense (?) to remove this community from any collection_items that once pointed to it... that would remove it from watchlists and the like,
      # though, and I don't know if that's wise (since then they wouldn't see the delete log item).
      flash[:notice] = I18n.t(:community_destroyed)
    else
      flash[:error] = I18n.t(:community_not_destroyed_error)
    end
    redirect_to(community_path(@community))
  end

  def join
    if @community.has_member?(current_user)
      redirect_to(@community, :notice => I18n.t(:already_member_of_community) )
    else
      @community.add_member(current_user)
      auto_collect(@community, :annotation => I18n.t(:user_joined_community_on_date, :date => I18n.l(Date.today),
                                                     :username => current_user.full_name))
      respond_to do |format|
        format.html { redirect_to(@community, :notice => I18n.t(:you_joined_community) + " #{flash[:notice]}" ) }
      end
    end
  end

  def leave
    respond_to do |format|
      begin
        @community.remove_member(current_user)
      rescue EOL::Exceptions::ObjectNotFound => e
        format.html { redirect_to(@community, :notice => I18n.t(:could_not_find_user)) }
      end
      format.html { redirect_to(@community, :notice => I18n.t(:you_left_community) ) }
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
    # It's okay (perfectly) if this gets overridden elsewhere:
    flash[:notice] = I18n.t(:this_community_was_deleted) unless @community.published?
    @community_collections = @community.collections || [] # NOTE these are collection_items, really.
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
