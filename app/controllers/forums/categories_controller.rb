class Forums::CategoriesController < ForumsController

  layout 'v2/forum'
  before_filter :restrict_to_admins
  before_filter :allow_login_then_submit, :only => [:create]

  # POST /create
  def create
    @category = ForumCategory.new(params[:forum_category])
    @category.user_id = current_user.id

    if @category.save
      flash[:notice] = 'Category was created'
    else
      flash[:error] = 'Category was not created'
      flash[:error] << " #{@category.errors.full_messages.join('; ')}." if @category.errors.any?
    end
    redirect_to forums_path
  end

  def destroy
    @category = ForumCategory.find(params[:id])
    if @category.forums.count == 0
      @category.destroy
      flash[:notice] = 'Category was deleted'
    else
      flash[:error] = 'Category was not empty'
    end
    redirect_to forums_path
  end

  def move_up
    @category = ForumCategory.find(params[:id])
    if @next_lowest = ForumCategory.where("view_order < #{@category.view_order}").order("view_order desc").limit(1).first
      new_view_order = @next_lowest.view_order
      @next_lowest.update_attributes(:view_order => @category.view_order)
      @category.update_attributes(:view_order => new_view_order)
      flash[:notice] = 'Category was moved'
    else
      flash[:error] = 'Category was not move'
    end
    redirect_to forums_path
  end

  def move_down
    @category = ForumCategory.find(params[:id])
    if @next_highest = ForumCategory.where("view_order > #{@category.view_order}").order("view_order asc").limit(1).first
      new_view_order = @next_highest.view_order
      @next_highest.update_attributes(:view_order => @category.view_order)
      @category.update_attributes(:view_order => new_view_order)
      flash[:notice] = 'Category was moved'
    end
    redirect_to forums_path
  end

end
