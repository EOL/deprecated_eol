class Administrator::ReportsController < AdminController
  include ReportsControllerModule

  access_control :DEFAULT => 'Administrator - Usage Reports'
  
  layout 'admin'

  # as an administrator, you can filter everything by Agent
  # to see reports as a Content Partner would see them
  def current_agent
    ( params[:agent].to_i > 0 ) ? params[:agent].to_i : nil
  end
  
end
