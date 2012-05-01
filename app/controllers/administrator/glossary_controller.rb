class Administrator::GlossaryController < AdminController

  layout 'left_menu'

  helper :resources

  before_filter :set_layout_variables
  before_filter :restrict_to_admins

  def index
    @page = params[:page] || '1'
    @order = params[:order_by] || 'term'
    @search_string = params[:search_string] || ''
    @search_string.strip!
    @page_title = I18n.t("eol_glossary")
    unless @search_string.blank?
      @glossary_terms = GlossaryTerm.find_by_sql("SELECT * FROM glossary_terms WHERE term LIKE '%#{@search_string}%' OR definition LIKE '%#{@search_string}%'").paginate(:page => @page)
    else
      @glossary_terms = GlossaryTerm.all(:order => "#{@order}").paginate(:page => @page)
    end
  end

  def create
    if params[:glossary_term][:term].blank?
      flash[:error] = I18n.t("term_cannot_be_left_blank")
      redirect_to :action => 'index', :status => :moved_permanently
    elsif GlossaryTerm.find_by_term(params[:glossary_term][:term])
      flash[:error] = I18n.t(:term_is_already_def_error, :term => params[:glossary_term][:term] )
      redirect_to :action => 'index', :status => :moved_permanently
    else
      GlossaryTerm.create(params[:glossary_term])
      redirect_to :action => 'index', :status => :moved_permanently
    end
  end

  def edit
    @page_title = I18n.t("eol_glossary")
    @glossary_term = GlossaryTerm.find(params[:id])
  end

  def update
    @glossary_term = GlossaryTerm.find(params[:id])
    if @glossary_term.update_attributes(params[:glossary_term])
      flash[:notice] = I18n.t("the_glossary_term_was_successf")
      redirect_to :action => 'index', :status => :moved_permanently
    else
      render :action => 'edit'
    end
  end

  def destroy
    (redirect_to referred_url, :status => :moved_permanently;return) unless request.method == :delete
    term = GlossaryTerm.find(params[:id])
    term.destroy
    redirect_to referred_url, :status => :moved_permanently
  end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
