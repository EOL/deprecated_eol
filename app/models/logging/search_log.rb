class SearchLog < LoggingModel
  belongs_to :ip_address  
  belongs_to :taxon_concept
  
  validates_presence_of :search_term

  def self.log(params, request, user)

     return nil if params.blank?
     
     opts = {
       :ip_address_raw => IpAddress.ip2int(request.remote_ip),
       :user_agent => request.user_agent || 'unknown',
       :path => request.request_uri || 'unknown'
     }
     opts[:user_id] = user.id unless user.nil?
     
     result = create_log opts.merge(params)

     return result
     
  end
  
  def self.create_log(opts)
    logger.warn('Bogus invokation of SearchLog creation function!') and return if opts.nil?  
    l = SearchLog.create opts
    return l
  end
  
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

end
