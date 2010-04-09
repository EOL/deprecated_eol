class SearchLogsController < AdminController

  layout 'admin'

# TODO (Low Priority) - Move this into the "administrator" folder for consistency, may need to update routes.rb file

  access_control :DEFAULT => 'Administrator - Usage Reports'
  
  def index
    
    @page_title = 'Search Term Reports'
    @term_search_string=params[:term_search_string]
    @order_by=params[:order_by] || "frequency"
    @sort_order=params[:sort_order] || "DESC"
    
    term_search_string='%' + @term_search_string + '%' unless @term_search_string.blank?
   
    sql=Array.new
    sql[0]="select distinct(search_term),count(search_term) as frequency,search_type,avg(total_number_of_results) as results_avg,avg(number_of_common_name_results) as common_name_avg,avg(number_of_scientific_name_results) as scientific_name_avg,avg(number_of_suggested_results) as suggested_results_avg,avg(number_of_stub_page_results) as stub_page_avg from search_logs"
    sql[0]+=" WHERE search_term LIKE ?" unless term_search_string.blank?
    sql[0]+=" GROUP BY search_term ORDER BY " + @order_by + " " + @sort_order
    
    sql << term_search_string unless term_search_string.blank?
    
    @search_report = SearchLog.paginate_by_sql(ActiveRecord::Base.eol_escape_sql(sql),:page=>params[:page] || "1",:per_page => params[:per_page] || "30")
    
    @search_totals = SearchLog.find_by_sql('select count(search_term) as num_searches,count(distinct(search_term)) as distinct_searches from search_logs')
    
  end
  
  def show
    @page_title = 'Search Term Detail Report'
    @search_term=params[:id]
    @frequency=SearchLog.count(:conditions=>["search_term=?",@search_term])
    @clicked_taxa=SearchLog.find_by_sql(["select distinct(taxon_concept_id),count(taxon_concept_id) as frequency from search_logs where search_term=? GROUP BY taxon_concept_id ORDER BY frequency desc",@search_term])
  end
        
protected
  def find_average(a_dict)
    data = a_dict.to_a
    count = data.inject(0) {|res, rec| res += rec[1].to_i}
    sum = data.inject(0) {|res, rec| res += rec[0].to_i * rec[1].to_i}
    sum/count rescue 0
  end
end
