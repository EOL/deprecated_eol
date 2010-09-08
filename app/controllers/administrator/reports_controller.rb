class Administrator::ReportsController < AdminController
  include ReportsControllerModule

  layout 'left_menu'

  before_filter :set_layout_variables

  access_control :DEFAULT => 'Administrator - Usage Reports'
  
  # as an administrator, you can filter everything by Agent
  # to see reports as a Content Partner would see them
  def current_agent
    ( params[:agent].to_i > 0 ) ? params[:agent].to_i : nil
  end
  
private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
