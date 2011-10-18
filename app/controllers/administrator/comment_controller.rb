class Administrator::CommentController  < AdminController

  layout 'left_menu'

  before_filter :set_layout_variables

  before_filter :restrict_to_admins

  def index

    @page_title = I18n.t("user_comments")
    @term_search_string=params[:term_search_string] || ''
    search_string_parameter='%' + @term_search_string + '%'
    @comments=Comment.paginate(:conditions=>['body like ?',search_string_parameter],:order=>'created_at desc',:include=>:user,:page => params[:page])
    @comment_count=Comment.count(:conditions=>['body like ?',search_string_parameter])

  end

  def edit

    @page_title = I18n.t("edit_comment")
    store_location(referred_url) if request.get?
    @comment = Comment.find(params[:id])

  end

  def update

    @comment = Comment.find(params[:id])

    if @comment.update_attributes(params[:comment])
      flash[:notice] = I18n.t("the_comment_was_successfully_u")
      redirect_back_or_default(url_for(:action=>'index'))
    else
      render :action => 'edit'
    end

  end


  def destroy

    (redirect_to referred_url;return) unless request.method == :delete

    @comment = Comment.find(params[:id])
    @comment.destroy

    redirect_to referred_url

  end

  def hide
    @comment = Comment.find(params[:id])
    @comment.hide(current_user)
    clear_cached_homepage_activity_logs
    redirect_to referred_url
  end

  def show
    @comment = Comment.find(params[:id])
    @comment.show(current_user)
    clear_cached_homepage_activity_logs
    redirect_to referred_url
  end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
