class MembersController < ApplicationController

  layout 'v2/communities'

  before_filter :load_community_and_current_member
  before_filter :load_member, :except => [:index]
  before_filter :restrict_edit, :only => [:edit, :update, :grant_manager, :revoke_manager]
  before_filter :restrict_delete, :only => [:delete]

  def index
    @members = Member.paginate(:page => params[:page])

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
    respond_to do |format|
      format.html { redirect_to(@community, :notice =>  I18n.t(:you_removed_the_member_from_the_community) ) }
    end
  end

  def grant_manager
  end

  def revoke_manager
  end

private

  def load_community_and_current_member
    @community = Community.find(params[:community_id])
    @current_member = current_user.member_of(@community)
  end

  def load_member
    @member = Member.find(params[:id] || params[:member_id])
    unless @member && @member.community_id == @community.id
      flash[:error] =  I18n.t(:cannot_find_member)
      return redirect_to(@community)
    end
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

