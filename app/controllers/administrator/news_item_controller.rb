class Administrator::NewsItemController < AdminController

  access_control :DEFAULT => 'Administrator - News Items'
  before_filter :redirect_if_not_allowed_ip  # only allow MBL/EOL IP addresses
  
  def index
 
    @term_search_string=params[:term_search_string] || ''
    search_string_parameter='%' + @term_search_string + '%' 
    @news_items=NewsItem.paginate(:conditions=>['body like ?',search_string_parameter],:order=>'display_date desc',:page => params[:page])
    @news_items_count=NewsItem.count(:conditions=>['body like ?',search_string_parameter])
  
  end

  def new

    @news_item = NewsItem.new

  end

  def edit
    
    @news_item = NewsItem.find(params[:id])
  
  end

  def create
    
    @news_item = NewsItem.new(params[:news_item])

     if @news_item.save
      flash[:notice] = 'The news item was successfully created.'
      expire_cache('Home')
      redirect_to :action=>'index' 
     else
      render :action => 'new' 
    end
  
  end

  def update

    @news_item = NewsItem.find(params[:id])

    if @news_item.update_attributes(params[:news_item])
      flash[:notice] = 'The news item was successfully updated.'
      expire_cache('Home')
      redirect_to :action=>'index' 
    else
      render :action => 'edit' 
    end
 
  end


  def destroy
    
    (redirect_to :action=>'index';return) unless request.method == :delete
    
    @news_item = NewsItem.find(params[:id])
    @news_item.destroy
    expire_cache('Home')
      
    redirect_to :action=>'index' 
  
  end

end
