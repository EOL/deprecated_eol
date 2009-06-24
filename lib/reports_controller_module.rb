# Because ContentPartner::ReportsController and Administrator::ReportsController
# are the same, except they're in different namespaces / sections of the site
# and have different filters / authentication / etc, we put all of the actual
# logic in this module and simply include it within the 2 controllers
#
module ReportsControllerModule
  
  
  def index
    whole_report
    # render :template => 'reports/index'
  end

  def whole_report
    @act_histories    = 
                      ActionsHistory.find_all_by_object_id(agents_data_object_ids +
                        agents_comment_ids, :order => 'updated_at DESC')
        
    @sub_page_header  = 'Changing of objects status and comments'
    @report_type      = :whole_report
    
    render :template => 'reports/whole_report'
  end
  
  def comments_report
    @act_histories    = 
                      ActionsHistory.find_all_by_object_id(agents_comment_ids,
                        :order => 'updated_at DESC')
    @sub_page_header  = 'Changing of comments'
    @report_type      = :comments_report

    render :template => 'reports/comments_report'
  end

  def statuses_report
    @act_histories    = 
                      ActionsHistory.find_all_by_object_id(agents_data_object_ids,
                        :order => 'updated_at DESC')
    @sub_page_header  = 'Changing of objects status'
    @report_type      = :statuses_report
    
    render :template => 'reports/statuses_report'
  end

  private
  
  def agents_data_object_ids
    Agent.find(current_agent.id).agents_data.map {|x| x.id}
  end
  
  def agents_comment_ids 
    Comment.find_all_by_parent_id(agents_data_object_ids).map {|x| x.id if      (x.parent_type == "DataObject")}
  end  
  
  # def act_histories
  #   ActionsHistory.find_all_by_object_id(agents_data_object_ids + agents_comment_ids,
  #                                        :order => 'updated_at DESC')
  # end
  
end  
  # 
  # 
  #   def self.included base
  #     require 'csv'
  #     require 'geo_kit/geocoders'
  #     base.instance_eval {
  #       include GeoKit::Geocoders
  #       before_filter :set_report
  #       before_filter :enable_amcharts, :set_date_range, :set_show_other, :if => :valid_report?
  #     }
  #   end
  # 
  #   def index
  #     @admin_header="Data Usage Reports"
  #     render :template => 'reports/index'
  #   end
  # 
  #   # this is the only public method on this controller (except index). ALL calls go through this method (except index).
  #   # see config/routes.rb
  #   def catch_all
  #     unless valid_report?
  #       render :text => "Report not found for #{ params[:report] }", :status => 404
  #       return
  #     end
  #     
  #     @admin_header="Data Usage Reports - #{params[:report].capitalize.gsub('_',' ')}"
  #     @this_month_start_date=Date.today - Date.today.day.day+1
  #     @this_month_end_date=Date.today
  #     @last_month_start_date=(Date.today - Date.today.day.day+1)-1.month
  #     @last_month_end_date=Date.today - Date.today.day.day
  #     @this_year_start_date=Date.today.year.to_s+'-01-01'
  #     @this_year_end_date=Date.today
  #     
  #     # throwing this here for now ...
  #     @show_agent = current_agent.nil?
  #     if RAILS_ENV == 'development' and params[:report][/\/mine!$/]
  #       @log_daily_class.delete_all
  #       @log_daily_class.mine 
  #     end
  #     @totals = @log_daily_class.grand_totals @start_date..@end_date, :agent => current_agent, :include_percentage => true, 
  #                                  :page => params[:page], :per_page => ( params[:per_page] || LogDaily::DEFAULT_PER_PAGE )
  #     calculate_percentages
  # 
  #     if params[:report][/_settings$/]
  #       chart_settings
  #     elsif params[:report][/_data$/]
  #       chart_data
  #     else
  #       report
  #     end
  #   end
  # 
  #   # here be the 'actions'
  #   protected
  # 
  #   def report
  #     # because of our abnormal path handling, respond_to doesn't seem to work here ...
  #     if params[:report][/\.xml$/]
  #       render :xml => @totals.to_xml
  # 
  #     elsif params[:report][/\.csv$/]
  #       render :text => @totals.to_csv(:except => [:data_type_id, :day])
  #       response.headers['Content-Type'] = 'text/csv; charset=iso-8859-1; header=present'
  #       response.headers['Content-Disposition'] = "attachment; filename=#{@report}_#{Time.now.strftime("%m-%d-%Y")}.csv"
  # 
  #     else
  #       render :template => 'reports/generic'
  #     end
  #   end
  # 
  #   def chart_data
  #       chart = Ambling::Data::Pie.new()
  #       @totals.each do |n|
  #         chart.slices << Ambling::Data::Slice.new( round_to_2_decimal_places(n.percentage), :title => n.unique_data_to_s )
  #       end
  #       chart.slices << Ambling::Data::Slice.new( round_to_2_decimal_places(@other_percentage), :title => "Other" ) if @show_other and @others_to_show
  #       xml = chart.to_xml
  #       render :xml => xml
  #   end
  # 
  #   def chart_settings
  #     settings = default_pie_chart_settings('Stuff')
  #     render :xml => settings.to_xml
  #   end
  # 
  #   private 
  # 
  #   def round_to_2_decimal_places number
  #     sprintf( "%.2f", number ).to_f
  #   end
  # 
  #   def valid_report?
  #     @report and @log_daily_class
  #   end
  # 
  #   # calculate percentages and whether there is an 'Other' part of the data to show ...
  #   def calculate_percentages
  #     return false if @totals.empty?
  #     total_percentage = @totals.inject(0){|all,this| all += this.percentage }
  #     @other_percentage = 100 - total_percentage
  #     @others_to_show = (@other_percentage > 0.0 and total_percentage > 0.0) 
  #   end
  #   
  #   def enable_amcharts
  #     @amcharts = true
  #   end
  # 
  #   # report is required for set_date_range so ... might as well run it once, as a before_filter
  #   def set_report
  #     @report = ( params[:report].nil? ) ? nil : params[:report].sub(/_data$/,'').sub(/_settings$/,'').sub(/\.(\w+)$/,'').sub(/\/mine!$/,'')
  #     if @report
  #       begin 
  #         @log_daily_class = "#{ @report.singularize }_log_daily".classify.constantize
  #       rescue NameError
  #         @report = nil # nil out @report because it's invalid ... we don't want to do anything but display a 404 message
  #       end
  #     end
  #   end
  # 
  #   # whether or not to show the 'other' part of graphs
  #   def set_show_other
  #     @show_other = ( params[:show_other] != 'false' )
  #   end
  # 
  #   def set_date_range
  #     start_date_key = "usage_report_#{ @report }_start_date"
  #     end_date_key   = "usage_report_#{ @report }_end_date"
  # 
  #     # set defaults (assuming no params passed in)
  #     @start_date = session[start_date_key] || Date.today - 1.week
  #     @end_date   = session[end_date_key]   || Date.today
  # 
  #     # if params were passed in, try to parse them as dates (else fall back to defaults)
  #     @start_date = parse_date params[:start_date], @start_date if params[:start_date]
  #     @end_date   = parse_date params[:end_date],   @end_date   if params[:end_date]
  # 
  #     # update session
  #     session[start_date_key] = @start_date
  #     session[end_date_key]   = @end_date
  #   end
  #    
  #   def default_pie_chart_settings(name)
  #     Ambling::Pie::Settings.new(
  #     {
  #       :pie => {
  #         :radius => 150,
  #         :colors => '0xFF0F00,0xFF6600,0xFF9E01,0xFCD202,0xF8FF01,0xB0DE09,0x04D215,0x0D8ECF,0x0D52D1,0x2A0CD0,0x8A0CCF,0xCD0D74',
  #         #'#0099BB,#999922,#008900',
  #         :outline_color => '#000000',
  #         :outline_alpha => 50,
  #         :angle => 10,
  #         :height => 10,
  #       },
  #       :animation => {
  #         :start_time => 0.5,
  #         :start_effect => 'regular',
  #         :pull_out_time => 1.5,
  # #        :pull_out_effect => 'bounce',
  #         :pull_out_on_click => true
  #       },
  #       :data_labels => {
  #         :show => '{title}: {percents}%', 
  #         :line_color => '#3e3e3e',
  #         :line_alpha => 20,
  #         :hide_labels_percent => 3
  #       },
  #       :legend => {
  #         :enabled => true,
  #         :border_alpha => 20,
  #         :margins => 5
  #       },
  #       :balloon => {
  #         :enabled => true,
  #         :alpha => 80,
  #         :show => '{title}: {value} ({percents}%)'
  #       },
  #       :labels => {
  #         :label => {
  #           :text => name,
  #           :text_size => 12},
  #       }
  #     }
  #     )
  #   end
  # 
  #   # little helper method for parsing a Date (and returning a default date if the parse fails)
  #   def parse_date str, default_date = Date.today
  #     begin
  #       (str.nil? or str.empty?) ? default_date : Date.parse( str )
  #     rescue ArgumentError
  #       default_date
  #     end
  #   end
  # 
  # end
  
  