class Forums::CategoriesController < ForumsController

  layout 'forum'
  before_filter :restrict_to_admins
  before_filter :allow_login_then_submit, only: [:create]

  # GET /forum_categories/new
  def new
  end

  # POST /forum_categories
  def create
    @category = ForumCategory.new(params[:forum_category])
    @category.user_id = current_user.id

    if @category.save
      flash[:notice] = I18n.t('forums.categories.create_successful')
    else
      flash[:error] = I18n.t('forums.categories.create_failed')
      render :new
      return
    end
    redirect_to forums_path
  end

  # GET /forum_categories/:id/edit
  def edit
    @category = ForumCategory.find(params[:id])
    
    raise EOL::Exceptions::SecurityViolation.new("User with ID=#{current_user.id} does not have edit access to ForumCategory with ID=#{@category.id}",
    :missing_edit_acess_to_forum_category) unless current_user.can_update?(@category)
  end

  # PUT /forum_categories/:id
  def update
    @category = ForumCategory.find(params[:id])
    raise EOL::Exceptions::SecurityViolation.new("User with ID=#{current_user.id} does not have edit access to ForumCategory with ID=#{@category.id}",
    :missing_edit_acess_to_forum_category)unless current_user.can_update?(@category)
    if @category.update_attributes(params[:forum_category])
      flash[:notice] = I18n.t('forums.categories.update_successful')
    else
      flash[:error] = I18n.t('forums.categories.update_failed')
      render :edit
      return
    end
    redirect_to forums_path
  end

  # DELETE /forum_categories/:id
  def destroy
    @category = ForumCategory.find(params[:id])
    raise EOL::Exceptions::SecurityViolation.new("User with ID=#{current_user.id} does not have edit access to ForumCategory with ID=#{@category.id}",
    :missing_delete_acess_to_forum_category) unless current_user.can_delete?(@category)
    if @category.forums.count == 0
      @category.destroy
      flash[:notice] = I18n.t('forums.categories.delete_successful')
    else
      flash[:error] = I18n.t('forums.categories.delete_failed_not_empty')
    end
    redirect_to forums_path
  end

  # POST /forum_categories/:id/move_up
  def move_up
    @category = ForumCategory.find(params[:id])
    if @next_lowest = ForumCategory.where("view_order < #{@category.view_order}").order("view_order desc").limit(1).first
      new_view_order = @next_lowest.view_order
      @next_lowest.update_attributes(view_order: @category.view_order)
      @category.update_attributes(view_order: new_view_order)
      flash[:notice] = I18n.t('forums.categories.move_successful')
    else
      flash[:error] = I18n.t('forums.categories.move_failed')
    end
    redirect_to forums_path
  end

  # POST /forum_categories/:id/move_down
  def move_down
    @category = ForumCategory.find(params[:id])
    if @next_highest = ForumCategory.where("view_order > #{@category.view_order}").order("view_order asc").limit(1).first
      new_view_order = @next_highest.view_order
      @next_highest.update_attributes(view_order: @category.view_order)
      @category.update_attributes(view_order: new_view_order)
      flash[:notice] = I18n.t('forums.categories.move_successful')
    else
      flash[:error] = I18n.t('forums.categories.move_failed')
    end
    redirect_to forums_path
  end

end
