class Administrator::TranslationLogController < AdminController
  
  layout 'deprecated/left_menu'

  helper :resources
  
  def index
    @page = params[:page] || '1'
    
    @translation_logs = TranslationLog.all(order: "count desc").paginate(page: @page)
  end
  
end
