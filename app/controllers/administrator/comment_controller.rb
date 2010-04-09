class Administrator::CommentController  < AdminController

  access_control :DEFAULT => 'Administrator - Comments and Tags'
 
  def index
 
    @page_title = 'User Comments'
    @term_search_string=params[:term_search_string] || ''
    search_string_parameter='%' + @term_search_string + '%' 
    @comments=Comment.paginate(:conditions=>['body like ?',search_string_parameter],:order=>'created_at desc',:include=>:user,:page => params[:page])
    @comment_count=Comment.count(:conditions=>['body like ?',search_string_parameter])
  
  end

  def edit

    @page_title = 'Edit Comment'
    store_location(referred_url) if request.get?    
    @comment = Comment.find(params[:id])
  
  end

  def update

    @comment = Comment.find(params[:id])
    
    if @comment.update_attributes(params[:comment])
      flash[:notice] = 'The comment was successfully updated.'
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
  
end
