class AdminController < ApplicationController
  
 layout 'main'
 
 before_filter :check_authentication
 access_control :DEFAULT => 'administrator'

 def redirect_if_not_allowed_ip
   unless allowed_request
     flash[:warning]='You are not authorized to enter this area.'
     redirect_to home_page_url 
   end
 end
    
 def index

 end
      
end
