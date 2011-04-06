class CommunitiesController < ApplicationController

  layout 'v2/communities'

  before_filter :load_community_and_dependent_vars, :except => [:index, :new, :create]
  before_filter :must_be_logged_in, :except => [:index, :show]
  before_filter :restrict_edit_and_delete, :only => [:edit, :update, :delete]

  def index
    @communities = Community.paginate(:page => params[:page])
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @communities }
    end
  end

  def show
    @feed_item = FeedItem.new_for(:feed => @community, :user => current_user)
    @page_title = I18n.t("community__var___community_nam", :var___community_name_ =>  @community.name )
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @community }
    end
  end

  def new
    @page_title = I18n.t(:create_a_new_community)
    @community = Community.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @community }
    end
  end

  def edit
    @page_title = I18n.t(:edit_community)
  end

  def create
    @community = Community.new(params[:community])
    respond_to do |format|
      if @community.save
        @community.initialize_as_created_by(current_user)
        format.html { redirect_to(@community, :notice =>  I18n.t(:created_community) ) }
        format.xml  { render :xml => @community, :status => :created, :location => @community }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @community.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

    respond_to do |format|
      if @community.update_attributes(params[:community])
        format.html { redirect_to(@community, :notice =>  I18n.t(:updated_community) ) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @community.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @community.destroy
    respond_to do |format|
      format.html { redirect_to(communities_url) }
      format.xml  { head :ok }
    end
  end

  def join
    @community.add_member(current_user)
    respond_to do |format|
      format.html { redirect_to(@community, :notice =>  I18n.t(:you_joined_community) ) }
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
    debugger if params[:id] !~ /^\d+$/
    @community = Community.find(params[:community_id] || params[:id])
    @members = @community.members # Because we pull in partials from the members controller.
    @current_member = current_user.member_of(@community)
  end

  def restrict_edit_and_delete
    @current_member ||= current_user.member_of(@community)
    raise EOL::Exceptions::SecurityViolation unless @current_member && @current_member.can?(Privilege.edit_delete_community)
  end

  def must_be_logged_in
    raise EOL::Exceptions::MustBeLoggedIn unless logged_in?
  end

end
