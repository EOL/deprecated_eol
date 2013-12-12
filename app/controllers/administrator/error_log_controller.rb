class Administrator::ErrorLogController < AdminController

  layout 'deprecated/left_menu'

  before_filter :set_layout_variables

  before_filter :restrict_to_admins

  def index
    @page_title = I18n.t("error_log")
    if params[:date]
      if params[:date] == 'all'
        @date = 'all'
      else
        @date = Time.parse(params[:date])
      end
    else
      @date = Time.now
    end
    conditions = "created_at BETWEEN '#{@date.strftime("%Y-%m-%d")}' AND '#{(@date+1.day).strftime("%Y-%m-%d")}'" if @date != 'all'
    @errors = ErrorLog.paginate(order: 'id desc', page: params[:page], conditions: conditions)

    @distinct_dates = []
    last_date = Time.now
    for i in 1..30
      date = last_date.strftime("%d-%b-%Y")
      @distinct_dates << [date, date]
      last_date = last_date - 1.day
    end
  end

  def show
    @page_title = I18n.t("error_log_detail")
    @error = ErrorLog.find(params[:id])
  end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
