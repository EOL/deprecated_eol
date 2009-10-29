class AdminController < ApplicationController
  
 layout 'main'
 
 before_filter :check_authentication
 access_control :DEFAULT => 'administrator'
    
 def index

 end
      
end
