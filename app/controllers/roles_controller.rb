class RolesController < ApplicationController

  layout 'main'

  before_filter :load_community_and_dependent_vars, :except => [:add_privilege, :remove_privilege]
  before_filter :restrict_access, :only => [:new, :edit, :create, :update, :delete]
  before_filter :load_role, :except => [:index, :new, :create]
  before_filter :load_all_privileges, :only => [:show, :new]

  def index
    @roles = Role.paginate(:page => params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @roles }
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @role }
    end
  end

  def new
    @role = Role.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @role }
    end
  end

  def edit
  end

  def create
    @role = Role.new(params[:role])
    @role.community = @community
    respond_to do |format|
      if @role.save
        add_privileges_to_role_from_hash(@role, params)
        format.html { redirect_to([@community, @role], :notice => 'Role was successfully created.') }
        format.xml  { render :xml => @role, :status => :created, :location => @role }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @role.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @role.update_attributes(params[:role])
        format.html { redirect_to([@community, @role], :notice => I18n.t(:role_was_successfully_updated) ) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @role.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    Role.destroy(@role.id)
    respond_to do |format|
      format.html { redirect_to(@community, :notice => I18n.t(:role_was_successfully_removed) ) }
      format.xml  { head :ok }
    end
  end

  def add_privilege
    respond_to do |format|
      if @role.add_privilege(Privilege.find(params[:privilege_id]))
        format.html { redirect_to([@role.community, @role], :notice => I18n.t(:role_was_successfully_updated) ) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @role.errors, :status => :unprocessable_entity }
      end
    end
  end

  def remove_privilege
    respond_to do |format|
      if @role.remove_privilege(Privilege.find(params[:privilege_id]))
        format.html { redirect_to([@role.community, @role], :notice => I18n.t(:role_was_successfully_updated) ) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @role.errors, :status => :unprocessable_entity }
      end
    end
  end

private

  def restrict_access
    @current_member ||= current_user.member_of(@community)
    raise EOL::Exceptions::SecurityViolation unless @current_member && @current_member.can?(Privilege.edit_community)
  end

  def load_community_and_dependent_vars
    @community = Community.find(params[:community_id])
    @current_member = current_user.member_of(@community)
  end

  def load_role
    @role = Role.find(params[:id] || params[:role_id])
  end

  def load_all_privileges
    @privileges = Privilege.all_for_community(@community)
  end

  def add_privileges_to_role_from_hash(role, hash)
    priv_re = /^privilege_(\d+)/
    hash.keys.each do |key|
      if key =~ priv_re
        pid = $1
        priv = Privilege.find(pid) rescue nil
        if priv && hash["privilege_#{pid}"]
          role.privileges << priv if priv
        end
      end
    end
  end

end
