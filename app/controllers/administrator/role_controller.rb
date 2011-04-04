class Administrator::RoleController < AdminController

  layout 'left_menu'

  before_filter :set_layout_variables

  helper :resources

  access_control :technical

  def index
    @page_title = I18n.t(I18n.t("roles"))
    @roles=Role.find(:all,:order=>'title')
  end

  def new
    @page_title = I18n.t("new_role")
    @role = Role.new
  end

  def edit
    @page_title = I18n.t("edit_role")
    @role = Role.find(params[:id])
  end

  def create
    @role = Role.new(params[:role])
    if @role.save
      flash[:notice] = I18n.t("the_role_was_successfully_crea")
      redirect_to :action=>'index' 
    else
      render :action => 'new' 
    end
  end

  def update
    @role = Role.find(params[:id])
    if @role.update_attributes(params[:role])
      flash[:notice] = I18n.t("the_role_was_successfully_upda")
      redirect_to :action=>'index' 
    else
      render :action => 'edit' 
    end
  end


  def destroy
    (redirect_to :action=>'index';return) unless request.method == :delete
    @role = Role.find(params[:id])
    @role.destroy
    redirect_to :action=>'index' 
  end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
