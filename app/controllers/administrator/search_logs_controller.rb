class Administrator::SearchLogsController < AdminController

  layout 'deprecated/left_menu'

  before_filter :set_layout_variables

  helper :resources

  before_filter :restrict_to_admins

  def index
    @page_title = I18n.t(:search_term_reports_title)
    @search_string = params[:search_string]
    @order         = params[:order] || "frequency"
    @reverse       = params[:reverse]
    @averages      = params[:averages]
    @search_totals = SearchLog.totals
    @search_report = SearchLog.paginated_report(:search_string => @search_string, :order => @order, :reverse => @reverse,
                                                :averages => @averages, :page => params[:page], :per_page => params[:per_page])
  end

  def show
    @page_title = I18n.t("search_term_detail_report")
    @search_term = params[:id]
    @frequency = SearchLog.count(:conditions=>["search_term=?",@search_term])
    @clicked_taxa = SearchLog.find_by_sql(["select distinct(taxon_concept_id),count(taxon_concept_id) as frequency from search_logs where search_term=? GROUP BY taxon_concept_id ORDER BY frequency desc",@search_term])
  end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

protected

  def find_average(a_dict)
    data = a_dict.to_a
    count = data.inject(0) {|res, rec| res += rec[1].to_i}
    sum = data.inject(0) {|res, rec| res += rec[0].to_i * rec[1].to_i}
    sum/count rescue 0
  end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
