class MembersController < ApplicationController

  layout 'v2/communities'

  before_filter :load_community_and_current_member
  before_filter :load_member, :except => [:index]
  before_filter :load_members, :only => [:index, :grant_manager, :revoke_manager]
  before_filter :restrict_edit, :only => [:edit, :update, :grant_manager, :revoke_manager]
  before_filter :restrict_delete, :only => [:delete]

  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @members }
    end
  end

  # This for non-members and members WITHOUT manager access:
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @member }
    end
  end

  # You must be a community manager to get here.
  def update
    respond_to do |format|
      if @member.update_attributes(params[:member])
        format.html { redirect_to(@member, :notice =>  I18n.t(:updated_member) ) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @member.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @community.remove_member(@member)
    flash[:notice] = I18n.t(:you_removed_the_member_from_the_community)
    redirect_to :action => 'index'
  end

  def grant_manager
    @member.grant_manager
    redirect_to :action => 'index'
  end

  def revoke_manager
    @member.revoke_manager
    redirect_to :action => 'index'
  end

private

  def load_community_and_current_member
    begin
      @community = Community.find(params[:community_id])
    rescue => e
      @page_title = I18n.t(:error_404_page_title)
      @message = e.message
      render(:layout => 'v2/errors', :template => "content/missing", :status => 404)
      return false
    end
    unless @community.published?
      render :template => '/communities/show'
      return false
    end
    @community_collections = @community.collections # NOTE these are really collection_items.
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
    @all_members = @managers + @nonmanagers
    @members = @all_members.paginate(:page => params[:page])
  end

  def restrict_edit
    @current_member ||= current_user.member_of(@community)
    raise EOL::Exceptions::SecurityViolation unless @current_member && @current_member.manager?
  end

  def restrict_delete
    @current_member ||= current_user.member_of(@community)
    raise EOL::Exceptions::SecurityViolation unless @current_member && @current_member.manager?
  end

end

