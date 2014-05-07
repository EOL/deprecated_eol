class PermissionsController < ApplicationController

  before_filter :restrict_to_admins

  layout 'permissions'

  # GET /permissions
  # GET /permissions.json
  def index
    @permissions = Permission.all
    @page_title = I18n.t(:permissions_list_header)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @permissions }
    end
  end

  # GET /permissions/1
  # GET /permissions/1.json
  def show
    @permission = Permission.find(params[:id])
    @page_title = I18n.t(:edit_permission_header, permission: @permission.name)


    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @permission }
    end
  end

end
