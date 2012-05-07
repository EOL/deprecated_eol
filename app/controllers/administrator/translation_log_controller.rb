class Administrator::TranslationLogController < AdminController
  
  layout 'left_menu'

  helper :resources
  
  def index
    @page = params[:page] || '1'
    
    @translation_logs = Logging::TranslationLog.all(:order => "count desc").paginate(:page => @page)    
  end
  
end