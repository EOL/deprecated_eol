class SiteConfigurationOptionsController < ApplicationController

  before_filter :restrict_to_admins

  def change
    @sco = SiteConfigurationOption.where(parameter: params[:parameter]).first
    val = params[:value]
    val = nil if val == 'false'
    val = true if val == 'true'
    @sco.value = val
    @sco.save
  end

end
