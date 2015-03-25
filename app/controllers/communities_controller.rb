class CommunitiesController < ApplicationController

  layout 'communities'

  before_filter :allow_login_then_submit, only: [:join]
  before_filter :load_community_and_dependent_vars, except: [:index, :new, :create, :choose, :make_editors]
  before_filter :load_collection, only: [:new, :create]
  before_filter :_must_be_logged_in, except: [:index, :show]
  before_filter :restrict_edit, only: [:edit, :update, :delete]

  # TODO: is this action being used, if not we should probably delete it along with it's view.
  def index
    @communities = Community.paginate(page: params[:page])
    respond_to do |format|
      # format.html # index.html.erb
      format.xml  { render xml: @communities }
    end
  end

  # TODO: are we using the XML format here? If not we're needlessly loading @community
  def show
    respond_to do |format|
      format.html { redirect_to(community_newsfeed_path(params[:id] || params[:community_id]), status: :moved_permanently) }
      format.xml  { render xml: @community }
    end
  end

  def new
    @page_title = I18n.t(:create_a_community)
    render action: 'new', layout: 'new_community'
  end

  def edit
    @page_title = I18n.t(:edit_community)
  end

  def create
    # accepts_nested_attributes_for doesn't fully work on create... it'll work on update, though, so we deal w/ it:
    if @collection.watch_collection?
      flash[:error] = I18n.t(:cannot_create_community_from_watch_collection_error)
      return redirect_to @collection
    end
    @community = Community.new(params[:community])
    if @community.save
      @collection.communities << @community
      @community.initialize_as_created_by(current_user)
      sent_to = send_invitations(find_invitees)
      notice = I18n.t(:created_community)
      notice += " #{I18n.t(:sent_invitations_to_users, count: sent_to.length, users: sent_to.to_sentence)}" unless sent_to.empty?
      upload_logo(
        @community,
        name: params[:community][:logo].original_filename
      ) unless params[:community][:logo].blank?
      EOL::GlobalStatistics.increment('communities') if @community.published?
      log_action(:create)
      auto_collect(@community)
      @community.collections.each do |focus|
        auto_collect(focus)
      end
      redirect_to(community_newsfeed_path(@community), notice: notice, status: :moved_permanently)
    else
      flash.now[:error] = I18n.t(:create_community_unsuccessful_error)
      render action: "new", layout: 'new_community'
    end
  end

  def update
    name_change = params[:community][:name] != @community.name
    description_change = params[:community][:description] != @community.description
    #TODO = icon_change
    respond_to do |format|
      if @community.update_attributes(params[:community])
        sent_to = send_invitations(find_invitees)
        notice = I18n.t(:updated_community)
        notice += " #{I18n.t(:sent_invitations_to_users, users: sent_to.to_sentence, count: sent_to.count)}" unless sent_to.empty?
        upload_logo(
          @community,
          name: params[:community][:logo].original_filename
        ) unless params[:community][:logo].blank?
        log_action(:change_name) if name_change
        log_action(:change_description) if description_change
        format.html { redirect_to(community_newsfeed_path(@community), notice: notice, status: :moved_permanently) }
        format.xml  { head :ok }
      else
        format.html { render action: "edit" }
        format.xml  { render xml: @community.errors, status: :unprocessable_entity }
      end
    end
  end

  # Note this is not "destroy".  That's because it's different: the community instance is not destroyed, AND this is
  # a :get, not a :post.
  def delete
    if @community.update_attributes(published: false)
      # Yeah, I really don't care if this fails. It's just convenience:
      @community.collection.update_attributes(published: false) rescue nil
      begin
        @community.remove_member(current_user)
      rescue EOL::Exceptions::ObjectNotFound => e
        flash[:error] = I18n.t(:could_not_find_user)
      end
      EOL::GlobalStatistics.decrement('communities')
      log_action(:delete)
      # TODO - it might make sense (?) to remove this community from any collection_items that once pointed to it...
      # that would remove it from watchlists and the like, though, and I don't know if that's wise (since then they
      # wouldn't see the delete log item).
      flash[:notice] = I18n.t(:community_destroyed)
    else
      flash[:error] = I18n.t(:community_not_destroyed_error)
    end
    redirect_to(community_newsfeed_path(@community), status: :moved_permanently)
  end

  def join
    if @community.has_member?(current_user)
      redirect_to(community_newsfeed_path(@community), notice: I18n.t(:already_member_of_community) , status: :moved_permanently)
    else
      member = @community.add_member(current_user)
      if @community.is_curator_community? && ! current_user.is_curator?
        flash[:notice] = I18n.t(:would_you_like_to_become_a_curator_notice,
                                url: curation_privileges_user_url(current_user))
      end
      log_action(:join, community: @community, member_id: member.id)
      auto_collect(@community, annotation: I18n.t(:user_joined_community_on_date, date: I18n.l(Date.today),
                                                     username: current_user.full_name))
      @community.collections.each do |focus|
        auto_collect(focus)
      end
      respond_to do |format|
        format.html { redirect_to(community_newsfeed_path(@community), notice: I18n.t(:you_joined_community) + " #{flash[:notice]}" , status: :moved_permanently) }
      end
    end
  end

  def leave
    respond_to do |format|
      begin
        @community.remove_member(current_user)
        log_action(:leave, community: @community)
      rescue EOL::Exceptions::ObjectNotFound => e
        format.html { redirect_to(community_newsfeed_path(@community), notice: I18n.t(:could_not_find_user)) }
      end
      format.html { redirect_to(community_newsfeed_path(@community), notice: I18n.t(:you_left_community)) }
    end
  end

  def choose
    return must_be_logged_in unless logged_in?
    @collection = Collection.find(params[:collection_id])
    @communities = current_user.members.managers.map {|m| m.community }.compact
    @page_title = I18n.t(:add_a_collection_to_a_community, collection: @collection.name)
    respond_to do |format|
      format.html { render '_choose', layout: 'collections' }
      format.js   { render partial: 'choose' }
    end
  end

  def revoke_editor
    collection = Collection.find(params[:collection_id])
    # TODO - second argument to constructor should be an I18n key for a human-readable error.
    raise EOL::Exceptions::SecurityViolation if collection.watch_collection?
    raise EOL::Exceptions::SecurityViolation if @community.collections.count <= 1
    @community.collections.delete(collection)
    flash[:notice] = I18n.t(:community_no_longer_has_manager_access_to_collection,
                            community: link_to_name(@community),
                            collection: link_to_collection(collection))
    respond_to do |format|
      format.html { redirect_to collection, status: :moved_permanently }
      format.js do
        convert_flash_messages_for_ajax
        render partial: 'shared/flash_messages', layout: false # JS will handle rendering these.
      end
    end
  end

  # One community and many collections were selected...
  def make_editor
    @notices = []
    @errors = []
    params[:collection_id].each do |id|
      collection = Collection.find(id)
      if collection.watch_collection?
        @errors << I18n.t(:error_watch_collections_cannot_be_shared)
      elsif collection && current_user.can_edit_collection?(collection)
        collection.communities << @community
        log_action(:add_collection, collection_id: collection.id)
        @notices << I18n.t(:collection_was_added_to_community,
                           collection: link_to_collection(collection))
      else
        @errors << I18n.t(:error_couldnt_find_collection_by_id, id: id)
      end
    end
    flash.now[:errors] = @errors.to_sentence unless @errors.empty?
    flash[:notice] = @notices.to_sentence unless @notices.empty?
    respond_to do |format|
      format.html { redirect_to community_newsfeed_path(@community), status: :moved_permanently }
      format.js do
        convert_flash_messages_for_ajax
        render partial: 'shared/flash_messages', layout: false # JS will handle rendering these.
      end
    end
  end

  # One collection and many communities were selected...
  def make_editors
    @notices = []
    @errors = []
    collection = Collection.find(params[:collection_id])
    if collection.watch_collection?
      @errors << I18n.t(:error_watch_collections_cannot_be_shared)
    else
      params[:community_id].each do |id|
        community = Community.find(id)
        if community && current_user.can_manage_community?(community)
          collection.communities << community
          log_action(:add_collection, community: community, collection_id: collection.id)
          @notices << I18n.t(:community_can_now_manage_this_collection,
                             community: link_to_name(community))
        else
          @errors << I18n.t(:error_couldnt_find_community_by_id, id: id)
        end
      end
    end
    flash.now[:errors] = @errors.to_sentence unless @errors.empty?
    flash[:notice] = @notices.to_sentence unless @notices.empty?
    respond_to do |format|
      format.html { redirect_to collection, status: :moved_permanently }
      format.js do
        convert_flash_messages_for_ajax
        render partial: 'shared/flash_messages', layout: false # JS will handle rendering these.
      end
    end
  end

protected

  def scoped_variables_for_translations
    @scoped_variables_for_translations ||= super.dup.merge({
      community_name: @community ? @community.name : nil,
      community_description: (@community && description = @community.description.presence) ?
        description : I18n.t(:community_description_default)
    }).freeze
  end

  def meta_open_graph_image_url
    @meta_open_graph_image_url ||= @community ?
      view_context.image_tag(@community.logo_url(linked?: true)) : nil
  end

private

  def load_community_and_dependent_vars
    @community = Community.find(params[:community_id] || params[:id])
    # It's okay (perfectly) if this gets overridden elsewhere:
    flash.now[:notice] = I18n.t(:this_community_was_deleted) unless @community.published?
    @community_collections = @community.featured_collections || [] # NOTE these are collection_items, really.
    @members = @community.members # Because we pull in partials from the members controller.
    @current_member = current_user.member_of(@community)
  end

  def load_collection
    @community = Community.new
    @collection = Collection.find(params[:collection_id])
    @community_collection = Collection.new(name: I18n.t(:copy_of_name, name: @collection.name))
  end

  def restrict_edit
    @current_member ||= current_user.member_of(@community)
    # TODO - second argument to constructor should be an I18n key for a human-readable error.
    raise EOL::Exceptions::SecurityViolation unless @current_member && @current_member.manager?
  end

  def _must_be_logged_in
    raise EOL::Exceptions::MustBeLoggedIn unless logged_in?
  end

  def log_action(act, opts = {})
    community = @community || opts.delete(:community)
    CommunityActivityLog.create(
      {community_id: community.id, user_id: current_user.id, activity_id: Activity.send(act).id}.merge(opts)
    )
  end

  def find_invitees
    if params[:invite_list]
      params[:invite_list].values
    elsif params[:invitations]
      params[:invitations].split(/[,\s]/).grep(/\w/)
    else
      []
    end
  end

  def send_invitations(usernames)
    sent_to = []
    not_sent_to = []
    usernames.each do |name|
      next if name.blank?
      begin
        user = User.find_by_username(name)
        comment = Comment.create(parent: user, user: current_user,
                                 body: I18n.t(:community_invitation_comment, community: link_to_name(@community)))
        sent_to << link_to_user(user)
      rescue
        not_sent_to << name
      end
    end
    unless not_sent_to.empty?
      flash[:error] = flash[:error].nil? ? '' : "#{flash[:error]} " # NOTE - add space if needed
      flash[:error] += I18n.t(:unable_to_invite_users_to_community_with_count, list: not_sent_to.to_sentence,
                              count: not_sent_to.count)
    end
    return sent_to
  end

  def link_to_user(who)
    self.class.helpers.link_to(who.username, user_path(who))
  end

  def link_to_name(community)
    self.class.helpers.link_to(community.name, community_path(community))
  end

  def link_to_collection(collection)
   self.class.helpers.link_to(collection.name, collection_path(collection))
  end

end
