class Administrator::GlossaryController < AdminController

  layout 'left_menu'

  helper :resources

  helper_method :current_agent, :agent_logged_in?

  before_filter :set_layout_variables
  
  access_control :DEFAULT => 'Administrator - Site CMS'
  
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
    if params[:glossary_term][:term].blank?
      flash[:error] = 'Term cannot be left blank'
      redirect_to :action => 'index'
    elsif GlossaryTerm.find_by_term(params[:glossary_term][:term])
      flash[:error] = "`#{params[:glossary_term][:term]}` is already defined"
      redirect_to :action => 'index'
    else
      GlossaryTerm.create(params[:glossary_term])
      redirect_to :action => 'index'
    end
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

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
