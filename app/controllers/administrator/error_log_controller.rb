class Administrator::ErrorLogController < AdminController

  layout 'deprecated/left_menu'

  before_filter :set_layout_variables

  before_filter :restrict_to_admins

  def index
    @page_title = I18n.t("error_log")
  end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
