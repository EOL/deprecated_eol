class MembersController < ApplicationController

  layout 'communities'

  before_filter :load_community_and_current_member
  before_filter :load_member, except: [:index]
  before_filter :load_members, only: [:index, :grant_manager, :revoke_manager]
  before_filter :restrict_edit, only: [:edit, :update, :grant_manager, :revoke_manager]
  before_filter :restrict_delete, only: [:delete]

  def index
    # TODO: It would make my life easier if this controller were nested under communities
    if @community
      set_canonical_urls(for: @community, paginated: @members, url_method: :community_members_url)
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @members }
    end
  end

  # This for non-members and members WITHOUT manager access:
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @member }
    end
  end

  # You must be a community manager to get here.
  def update
    respond_to do |format|
      if @member.update_attributes(params[:member])
        format.html { redirect_to(@member, notice:  I18n.t(:updated_member) ) }
        format.xml  { head :ok }
      else
        format.html { render action: "edit" }
        format.xml  { render xml: @member.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @community.remove_member(@member)
    flash[:notice] = I18n.t(:you_removed_the_member_from_the_community)
    redirect_to action: 'index',status: :moved_permanently
  end

  def grant_manager
    @member.grant_manager
    log_action(:add_manager)
    redirect_to action: 'index', status: :moved_permanently
  end

  def revoke_manager
    @member.revoke_manager
    redirect_to action: 'index', status: :moved_permanently
  end

protected
  def scoped_variables_for_translations
    @scoped_variables_for_translations ||= super.dup.merge({
      community_name: @community ? @community.name.presence : nil,
      community_description: (@community && description = @community.description.presence) ?
        description : I18n.t(:community_description_default),
      member_name: @member && @member.user ? @member.user.full_name.presence : nil
    }).freeze
  end

  def meta_open_graph_image_url
    @meta_open_graph_image_url ||= @community ?
      view_context.image_tag(@community.logo_url(linked?: true)) : nil
  end

private

  def load_community_and_current_member
    @community = Community.find(params[:community_id])
    unless @community.published?
      render template: '/communities/show'
      return false
    end
    @community_collections = @community.featured_collections # NOTE these are really collection_items.
    @current_member = current_user.member_of(@community)
  end

  def load_member
    @member = Member.find(params[:id] || params[:member_id])
    unless @member && @member.community_id == @community.id
      flash[:error] =  I18n.t(:cannot_find_member)
      return redirect_to(@community)
    end
  end

  def load_members
    @managers = @community.members.managers
    @nonmanagers = @community.members.nonmanagers
    @all_members = @community.members
    @members = @all_members.paginate(page: params[:page])
  end

  def restrict_edit
    @current_member ||= current_user.member_of(@community)
    
    raise EOL::Exceptions::SecurityViolation.new("User with id = #{current_user.id} tried to edit community with id = #{@community.id} but he is not a manager", 
    :only_managers_can_edit_community) unless @current_member && @current_member.manager?
  end

  def restrict_delete
    @current_member ||= current_user.member_of(@community)
    
    raise EOL::Exceptions::SecurityViolation.new("User with id = #{current_user.id} tried to delete community with id = #{@community.id} but he is not a manager", 
    :only_managers_can_delete_community) unless @current_member && @current_member.manager?
  end

  def log_action(act, opts = {})
    community = @community || opts.delete(community)
    CommunityActivityLog.create(
      {community: community, user: current_user, member: @member, activity: Activity.send(act)}.merge(opts)
    )
  end

end

