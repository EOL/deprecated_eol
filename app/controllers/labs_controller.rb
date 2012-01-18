class LabsController < ApplicationController

  layout 'labs/main'

  def index
    redirect_to 'http://labs.eol.org', :status => :moved_permanently
  end
  
end
