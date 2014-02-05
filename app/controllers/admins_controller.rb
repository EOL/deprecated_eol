class AdminsController < ApplicationController

  layout 'admin'

  before_filter :check_authentication
  before_filter :restrict_to_admins

  def show
    @page_title = I18n.t(:admin_page_title)
  end

end
