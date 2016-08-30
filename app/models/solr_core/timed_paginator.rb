class SolrCore::TimedPaginator
  def initialize(core, query, options = {})
    @solr = core
    @core_name = @solr.instance_eval { @core }
    @query = query
    @docs = []
    @per_page = options[:per_page] || 1000
  end

  def paginate(&block)
    EOL.log("SolrCore::TimedPaginator#paginate(#{@core_name})")
    @start = Time.now
    @done = 0
    @group_num = 0
    @page = 1
    while get_page
      yield(@docs)
      # Yes, re-calculating this, because it COULD change with each call!
      @groups = @size / @per_page
      @groups += 1 unless @size % @per_page == 0
      @page += 1
      @group_num += 1
      # if @group_num % 10 == 1
        @done += @docs.size
        elapsed = Time.now - @start
        pct = @done / @size.to_f * 100
        time_per_group = elapsed / @group_num
        groups_remaining = @groups - @group_num
        time_remaining = (groups_remaining * time_per_group).to_i
        EOL.log("#paginate: (#{@done}/#{@size}) "\
          "#{pct.round(3)}%, #{time_remaining}s remaining",
          prefix: ".")
      # end
    end
  end

  def get_page
    docs = @solr.paginate(@query, page: @page, per_page: @per_page)
    @size = docs["response"]["numFound"]
    @docs = docs["response"]["docs"]
    return ! @docs.empty?
  end
end
