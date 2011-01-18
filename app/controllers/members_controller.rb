class MembersController < ApplicationController
  layout 'main'
  before_filter :load_community_and_current_member
  before_filter :load_member, :except => [:index]
  before_filter :restrict_edit, :only => [:edit, :update]
  before_filter :restrict_delete, :only => [:delete]

  def index
    @members = Member.paginate(:page => params[:page]) 

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @members }
    end
  end

  # This for non-members and members WITHOUT access to change privileges:
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @member }
    end
  end

  # This is for community managers who have access to change privileges:
  def edit
    @privileges = Privilege.all_for_community(@member.community)
  end

  # You must be a community manager with privilege granting/revoking access to get here.
  def update
    respond_to do |format|
      if @member.update_attributes(params[:member])
        format.html { redirect_to(@member, :notice => 'Member was successfully updated.'[:updated_member]) }
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
      format.html { redirect_to(@community, :notice => 'You have successfully removed this member from the community.'[:you_removed_the_member_from_the_community]) }
    end
  end

private

  def load_community_and_current_member
    @community = Community.find(params[:community_id])
    @current_member = current_user.member_of(@community)
  end

  def load_member
    @member = Member.find(params[:id] || params[:member_id])
    unless @member && @member.community_id == @community.id
      flash[:error] = "Cannot find a member with this id."[:cannot_find_member]
      return redirect_to(@community)
    end
  end

  def restrict_edit
    @current_member ||= current_user.member_of(@community)
    raise EOL::Exceptions::SecurityViolation unless @current_member && @current_member.can_edit_members?
  end

  def restrict_delete
    @current_member ||= current_user.member_of(@community)
    raise EOL::Exceptions::SecurityViolation unless @current_member && @current_member.can?(Privilege.remove_members)
  end

end

