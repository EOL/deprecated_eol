class Administrator::ErrorLogController < AdminController
  
  access_control :DEFAULT => 'Administrator - Error Logs'
  
  def index
  
   if !params[:date].blank?
     @date=params[:date]
     conditions="date(created_at)='#{@date}'"
   end
   @errors=ErrorLog.paginate(:order=>'created_at desc',:page => params[:page],:conditions=>conditions)
   @errors_count=ErrorLog.count(:conditions=>conditions)
   
   @distinct_dates=ErrorLog.find(:all,:select=>'distinct(DATE_FORMAT(date(created_at),"%Y-%m-%d")) AS date',:order=>'created_at DESC')
   
 end
 
 def show
   
   @error=ErrorLog.find(params[:id])
   
 end
 
end
