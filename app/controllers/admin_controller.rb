class AdminController < ApplicationController
  
 layout 'left_menu'
 
 before_filter :check_authentication
 before_filter :set_no_cache
 before_filter :set_layout_variables

 access_control :DEFAULT => $ADMIN_ROLE_NAME
    
 def index
 end

private

 def set_no_cache
  @no_cache=true
 end      

 def set_layout_variables
   @page_title = 'EOL Administration Console'
   @navigation_partial = '/admin/navigation'
 end

end
