class AdminController < ApplicationController
  
 layout 'main'
 
 before_filter :check_authentication
 before_filter :set_no_cache
 
 access_control :DEFAULT => 'administrator'
    
 def index

 end

 def set_no_cache
  @no_cache=true
 end      

end
