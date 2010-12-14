class MembersController < ApplicationController
  layout 'main'
  # I can't imagine this view will be used often.  :\
  def index
    @members = Member.paginate(:page => params[:page]) 

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @members }
    end
  end

  # This for non-members and members WITHOUT access to change privileges:
  def show
    @member = Member.find(params[:id])
    @privileges = Privilege.all_for_community(@member.community)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @member }
    end
  end

  # This is for community managers who have access to change privileges:
  def edit
    @member = Member.find(params[:id])
  end

  # You must be a community manager with privilege granting/revoking access to get here.
  def update
    @member = Member.find(params[:id])

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

end

