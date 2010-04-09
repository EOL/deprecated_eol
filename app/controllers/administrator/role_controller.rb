class Administrator::RoleController < AdminController

  access_control :DEFAULT => 'Administrator - Technical'
  layout 'admin'

  def index
    @page_title = 'Roles'
    @roles=Role.find(:all,:order=>'title')
  end

  def new
    @page_title = 'New Role'
    @role = Role.new
  end

  def edit
    @page_title = 'Edit Role'
    @role = Role.find(params[:id])
  end

  def create
    @role = Role.new(params[:role])
    if @role.save
      flash[:notice] = 'The role was successfully created.'
      redirect_to :action=>'index' 
    else
      render :action => 'new' 
    end
  end

  def update
    @role = Role.find(params[:id])
    if @role.update_attributes(params[:role])
      flash[:notice] = 'The role was successfully updated.'
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

end
