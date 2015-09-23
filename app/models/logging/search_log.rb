class SearchLog < LazyLoggingModel
  establish_connection("#{Rails.env}_logging")

  belongs_to :ip_address
  belongs_to :taxon_concept

  validates_presence_of :search_term

  def self.log(params, request, user)

     return nil if params.blank?

     opts = {
       ip_address_raw: IpAddress.ip2int(request.remote_ip),
       user_agent: request.user_agent || 'unknown',
       path: request.url || 'unknown'
     }
     opts[:user_id] = user.id unless user.nil?

     begin
       create opts.merge(params)
     rescue => e
       Rails.logger.warn("Bogus invocation of SearchLog creation function by user #{user.id}")
       Rails.logger.warn(e.message)
       return nil
     end

  end

  # NOTE - this is only used by admins, and we might remove it.
  def self.click_times_by_taxon_concept_id(taxon_concept_id, start_date = nil, end_date = nil)
    sql=["select
            case
              when time_to_sec(timediff(clicked_result_at, created_at)) < 5
                then 'less than 5 seconds'
              when time_to_sec(timediff(clicked_result_at, created_at)) < 60
                then 'less than a minute'
              when time_to_sec(timediff(clicked_result_at, created_at)) is null
                then 'n/a'
              else 'more than a minute'
            end as response_time,
            count(*) as count
          from search_logs
          where taxon_concept_id = ?
          group by response_time", taxon_concept_id]
    SearchLog.find_by_sql(sql)
  end

  def self.paginated_report(options = {})
    order = options[:order] || 'frequency'
    order += " DESC" if options[:reverse]
    page  = options[:page] || 1
    per_page = options[:per_page] || 30
    sql = %q{
      SELECT
        DISTINCT(search_term),
        COUNT(search_term) AS frequency,
        search_type
    }
    sql += %q{,
        AVG(total_number_of_results) AS results_avg,
        AVG(number_of_common_name_results) AS common_name_avg,
        AVG(number_of_scientific_name_results) AS scientific_name_avg,
        AVG(number_of_suggested_results) AS suggested_results_avg,
        AVG(number_of_stub_page_results) AS stub_page_avg
    } if options[:averages]
    sql += " FROM search_logs"
    sql += " WHERE search_term LIKE ?" unless options[:search_string].blank?
    sql += " GROUP BY search_term ORDER BY #{order}"

    sql = [sql]
    sql << "%#{options[:search_string]}%" unless options[:search_string].blank?
    SearchLog.paginate_by_sql(ActiveRecord::Base.sanitize_sql_array(sql), page: page, per_page: per_page)
  end

  def self.totals
    SearchLog.find_by_sql(
      'SELECT COUNT(search_term) AS num_searches, COUNT(DISTINCT(search_term)) AS distinct_searches FROM search_logs'
    )[0]
  end

end
