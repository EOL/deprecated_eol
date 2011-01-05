class Administrator::HarvestingLogController < AdminController
  
  layout 'left_menu'
  before_filter :set_layout_variables
  access_control :DEFAULT => 'Administrator - Content Partners'
  
  def index
    @page_title = 'Harvesting Processes Log'
    unless params[:date].blank?
      if params[:date] == 'all'
        @date = 'all'
      else
        @date = Time.parse(params[:date])
      end
    else
      @date = 'all'
    end
    conditions = "began_at BETWEEN '#{@date.strftime("%Y-%m-%d")}' AND '#{(@date+1.day).strftime("%Y-%m-%d")}'" if @date != 'all'
    @logs = HarvestProcessLog.paginate(:order => 'id desc', :page => params[:page], :conditions => conditions)
    
    @distinct_dates = []
    last_date = Time.now
    for i in 1..30
      date = last_date.strftime("%d-%b-%Y")
      @distinct_dates << [date, date]
      last_date = last_date - 1.day
    end
  end
  
private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
