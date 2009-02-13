class Administrator::CommentController  < AdminController

  access_control :DEFAULT => 'Administrator - Comments and Tags'
 
  def index
 
    @term_search_string=params[:term_search_string] || ''
    search_string_parameter='%' + @term_search_string + '%' 
    @comments=Comment.paginate(:conditions=>['body like ?',search_string_parameter],:order=>'created_at desc',:include=>:user,:page => params[:page])
    @comment_count=Comment.count(:conditions=>['body like ?',search_string_parameter])
  
  end

  def edit
    
    @comment = Comment.find(params[:id])
  
  end

  def update

    @comment = Comment.find(params[:id])

    if @comment.update_attributes(params[:comment])
      flash[:notice] = 'The comment was successfully updated.'
      expire_cache('Home')
      redirect_to :action=>'index' 
    else
      render :action => 'edit' 
    end
 
  end


  def destroy
    
    (redirect_to :action=>'index';return) unless request.method == :delete
    
    @comment = Comment.find(params[:id])
    @comment.destroy
      
    redirect_to :action=>'index' 
  
  end
  
end