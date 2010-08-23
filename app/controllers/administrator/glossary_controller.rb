class Administrator::GlossaryController < AdminController
  helper :resources
  helper_method :current_agent, :agent_logged_in?
  layout 'admin'
  
  access_control :DEFAULT => 'Administrator - Content Partners'
  
  def index
    @page = params[:page] || '1'
    @order = params[:order_by] || 'term'
    @search_string = params[:search_string] || ''
    @search_string.strip!
    @page_title = 'EOL Glossary'
    unless @search_string.blank?
      @glossary_terms = GlossaryTerm.find_by_sql("SELECT * FROM glossary_terms WHERE term LIKE '%#{@search_string}%' OR definition LIKE '%#{@search_string}%'").paginate(:page => @page)
    else
      @glossary_terms = GlossaryTerm.all(:order => "#{@order}").paginate(:page => @page)
    end
  end
  
  def create
    GlossaryTerm.create(params[:glossary_term])
    redirect_to :action => 'index'
  end
  
  def edit
    @page_title = 'EOL Glossary'
    @glossary_term = GlossaryTerm.find(params[:id])
  end
  
  def update
    @glossary_term = GlossaryTerm.find(params[:id])
    if @glossary_term.update_attributes(params[:glossary_term])
      flash[:notice] = 'The glossary term was successfully updated.'
      redirect_to :action => 'index'
    else
      render :action => 'edit' 
    end
  end
  
  def destroy
    (redirect_to referred_url;return) unless request.method == :delete
    term = GlossaryTerm.find(params[:id])
    term.destroy
    redirect_to referred_url
  end
end
