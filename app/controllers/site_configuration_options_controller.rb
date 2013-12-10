class EolConfigsController < ApplicationController

  before_filter :restrict_to_admins

  def change
    @sco = EolConfig.find_or_create_by_parameter(params[:parameter])
    val = params[:value]
    val = nil if val == 'false'
    val = true if val == 'true'
    @sco.value = val
    @sco.save
  end

end
