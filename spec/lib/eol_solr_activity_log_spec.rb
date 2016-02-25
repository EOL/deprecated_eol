require "spec_helper"

# I couldn't help but notice while writing this spec that having a class/module that built Solr requests would have
# saved me a LOT of trouble ... and made everything much, much clearer. 
#
# TODO - create a Solr query builder class. It really shouldn't be too hard.  :|

describe EOL::Solr::ActivityLog do

  it '#index_notifications should have specs' 

  it '#global_activities should have specs' 

  it '#rebuild_comments_logs should have specs'

  it '#remove_watch_collection_logs should have specs'

  describe '#search_with_pagination' do

    def stub_empty_response
      stub_response(@empty_response)
    end

    def stub_response(resp)
      @result = []
      @result.stub(:read).and_return(resp)
      allow(EOL::Solr::ActivityLog).to receive(:open) { @result }
    end

    def call_arbitrary_query
      EOL::Solr::ActivityLog.search_with_pagination('foo')
    end

    # Brittle?  Hell yeah. We don't really care about these specifics. We don't care about the order... :|
    # ...Not sure what else to do, though.
    before(:all) do
      # it 'should query the SOLR_SERVER SOLR_ACTIVITY_LOGS_CORE'
      # it 'should get fields: activity_log_type,activity_log_id,user_id,date_created'
      load_foundation_cache
      EolConfig.destroy_all
      @request_head = "#{$SOLR_SERVER}#{$SOLR_ACTIVITY_LOGS_CORE}/select/?wt=json&q=%7B%21lucene%7D"
      @default_user_added_data_exclusion = "+NOT+action_keyword%3ADataPointUri+NOT+action_keyword%3AUserAddedData+NOT+activity_log_type%3AUserAddedData"
      @default_sort = "&sort=date_created+desc"
      @default_fields = "&fl=activity_log_type,activity_log_id,user_id,date_created"
      @default_group = "&group.field=activity_log_unique_key&group.ngroups=true&group=true"
      @default_rows = "&rows=30"
      @default_start = "&start=0"
      @recent_days = "&fq=date_created:[NOW/DAY-7DAY+TO+NOW/DAY%2B1DAY]"
      @default_tail = @default_fields + @default_group + @default_rows + @default_sort + @default_start
      @empty_response = '{"grouped":{"activity_log_unique_key":{"groups":[],"ngroups":0}}}'
    end

    it 'should have some reasonable default options' do
      stub_empty_response
      EOL::Solr::ActivityLog.should_receive(:open).with("#{@request_head}foo#{@default_user_added_data_exclusion +
        @default_tail}").and_return(@result)
      call_arbitrary_query
    end

    it 'should not exclude user_added_data if the user can see it' do
      stub_empty_response
      user = User.gen
      tail = @default_user_added_data_exclusion + @default_tail
      EOL::Solr::ActivityLog.should_receive(:open).with("#{@request_head}foo#{tail}").and_return(@result)
      EOL::Solr::ActivityLog.search_with_pagination('foo', user: user)
      # now grant the permission
      allow(EolConfig).to receive(:data?) {true}
      tail = @default_tail
      EOL::Solr::ActivityLog.should_receive(:open).with("#{@request_head}foo#{tail}").and_return(@result)
      EOL::Solr::ActivityLog.search_with_pagination('foo', user: user)
    end

    it 'should escape the query' do
      stub_empty_response
      CGI.should_receive(:escape).at_least(1).times.and_return('something') # nil would fail :+
      call_arbitrary_query
    end

    it 'should handle specific time ... whatever that means' do
      stub_empty_response
      EOL::Solr::ActivityLog.should_receive(:open).with("#{@request_head}foo#{@default_user_added_data_exclusion +
        @default_fields + @recent_days + @default_group + @default_rows + @default_sort + @default_start}").and_return(@result)
      EOL::Solr::ActivityLog.search_with_pagination('foo', recent_days: 7)
    end

    it 'should set start offset'

    it 'should set limit rows'

    it 'should convert to JSON'

    it 'should paginate with total results'

    it 'should paginate results'

    it 'should add resource instances'

    it 'should NOT add resource instances with skip_loading_instances'

    it 'should handle 0 results'

  end

end
