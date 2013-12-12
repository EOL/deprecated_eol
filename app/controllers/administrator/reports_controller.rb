class Administrator::ReportsController < AdminController

  layout 'deprecated/left_menu'

  before_filter :set_layout_variables

  before_filter :restrict_to_admins

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
